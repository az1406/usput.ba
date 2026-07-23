# frozen_string_literal: true

require "test_helper"

# Explore Bosnia: a 2x2 grid of the densest experience types deals the closest
# matching places as walk cards. Check-ins and moments ride a hidden per-user
# plan that never surfaces in plan listings.
class ExploreBosniaTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "wanderer", password: "password123")
    @history = ExperienceType.create!(key: "test-history", name: "History", active: true)
    @empty = ExperienceType.create!(key: "test-ghosts", name: "Ghosts", active: true)
    @near = Location.create!(name: "Close Fort", city: "Sarajevo", lat: 43.85, lng: 18.41,
                             suitable_experiences: [ @history.key ])
    @far = Location.create!(name: "Far Fort", city: "Mostar", lat: 43.34, lng: 17.81,
                            suitable_experiences: [ @history.key ])
  end

  teardown do
    [ @near, @far ].each { |location| location&.destroy }
    [ @history, @empty ].each { |type| type&.destroy }
    @user&.plans&.destroy_all
    @user&.destroy
  end

  test "the grid shows at most four tiles and never a type without geocoded places" do
    get explore_bosnia_path

    assert_response :success
    assert_select "[data-explore-geo-target='tile']", minimum: 1, maximum: 4
    assert_select "a[href=?]", explore_bosnia_experience_path(@empty.key), count: 0
  end

  test "the experience deck requires login" do
    get explore_bosnia_experience_path(@history.key)

    assert_redirected_to login_path
  end

  test "the experience deck renders scrollable cards with the swipe hint" do
    login_as(@user)

    get explore_bosnia_experience_path(@history.key)

    assert_response :success
    assert_select "[data-plan-deck-target='card']", count: 2
    assert_select "[data-plan-deck-target='hint']", count: 2
  end

  test "with coordinates the cards are closest first with a distance" do
    login_as(@user)

    get explore_bosnia_experience_path(@history.key, lat: 43.85, lng: 18.41)

    assert_response :success
    assert_operator response.body.index("Close Fort"), :<, response.body.index("Far Fort")
    assert_includes response.body, "km"
  end

  test "the deck never loads more than ten places" do
    12.times do |i|
      Location.create!(name: "Spot #{i}", city: "Sarajevo", lat: 43.8 + i * 0.001, lng: 18.4,
                       suitable_experiences: [ @history.key ])
    end
    login_as(@user)

    get explore_bosnia_experience_path(@history.key, lat: 43.85, lng: 18.41)

    assert_response :success
    assert_select "[data-plan-deck-target='card']", count: 10
  ensure
    Location.where("name LIKE 'Spot %'").destroy_all
  end

  test "a faraway visitor still gets the closest places dealt" do
    login_as(@user)

    get explore_bosnia_experience_path(@history.key, lat: 52.52, lng: 13.40)

    assert_response :success
    assert_select "[data-plan-deck-target='card']", count: 2
  end

  test "the story area offers upload, badges a private moment, and invites first publisher" do
    moment = @user.moments.new(plan: Plan.explore_bosnia_for(@user), location: @near, visibility: :private_moment)
    moment.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/real_image.jpg")), filename: "real_image.jpg", content_type: "image/jpeg")
    moment.save!
    login_as(@user)

    get explore_bosnia_experience_path(@history.key)

    assert_response :success
    assert_includes response.body, I18n.t("plans.start.story_add_private")
    assert_includes response.body, I18n.t("plans.start.story_private")
    # moments live in the story carousel only — the card's strip is gone in explore
    assert_select "form[action=?]", publish_plan_moment_path(moment.plan, moment), count: 1
  end

  test "an own approved public moment removes the be-first invitation" do
    moment = @user.moments.new(plan: Plan.explore_bosnia_for(@user), location: @near,
                               visibility: :public_moment)
    moment.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/real_image.jpg")), filename: "real_image.jpg", content_type: "image/jpeg")
    moment.save!
    moment.update!(moderation_status: :approved) # the curator's approval
    login_as(@user)

    get explore_bosnia_experience_path(@history.key)

    assert_response :success
    near_stories = css_select("##{ActionView::RecordIdentifier.dom_id(@near, :stories)}").first.to_s
    refute_includes near_stories, I18n.t("plans.start.story_none")
    far_stories = css_select("##{ActionView::RecordIdentifier.dom_id(@far, :stories)}").first.to_s
    assert_includes far_stories, I18n.t("plans.start.story_none")
  end

  test "publishing from the story actually publishes and streams the carousel back" do
    moment = @user.moments.new(plan: Plan.explore_bosnia_for(@user), location: @near, visibility: :private_moment)
    moment.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/real_image.jpg")), filename: "real_image.jpg", content_type: "image/jpeg")
    moment.save!
    login_as(@user)

    patch publish_plan_moment_path(moment.plan, moment),
          params: { context: "explore" },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert moment.reload.visibility_public_moment?
    assert moment.pending?
    assert_select "turbo-stream[action=replace][target=?]",
                  ActionView::RecordIdentifier.dom_id(@near, :stories), count: 1
  end

  test "deleting a moment from the story destroys it and its photo everywhere" do
    moment = @user.moments.new(plan: Plan.explore_bosnia_for(@user), location: @near, visibility: :private_moment)
    moment.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/real_image.jpg")), filename: "real_image.jpg", content_type: "image/jpeg")
    moment.save!
    blob_id = moment.photo.blob.id
    login_as(@user)

    delete plan_moment_path(moment.plan, moment),
           params: { context: "explore" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_not Moment.exists?(moment.id)
    perform_enqueued_jobs if respond_to?(:perform_enqueued_jobs)
    assert_not ActiveStorage::Blob.exists?(blob_id)
    assert_select "turbo-stream[action=replace][target=?]",
                  ActionView::RecordIdentifier.dom_id(@near, :stories), count: 1
  end

  test "a location's reviews render inside the card" do
    Review.create!(reviewable: @near, rating: 5, comment: "Amazing fortress views", author_name: "Mira")
    login_as(@user)

    get explore_bosnia_experience_path(@history.key)

    assert_response :success
    assert_includes response.body, "Amazing fortress views"
  end

  test "opening a deck creates the hidden plan and check-ins land on it" do
    login_as(@user)

    get explore_bosnia_experience_path(@history.key)
    hidden_plan = Plan.explore_bosnia_for(@user)

    assert_select "form[action=?]", plan_visits_path(hidden_plan), count: 2

    post plan_visits_path(hidden_plan),
         params: { location_id: @near.uuid, user_lat: 43.85, user_lng: 18.41 },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert hidden_plan.plan_visits.exists?(user: @user, location: @near)
  end

  test "a location visited on any plan is not offered as unvisited" do
    other_plan = Plan.create!(title: "Trip", visibility: :private_plan, user: @user)
    @user.plan_visits.create!(plan: other_plan, location: @near)
    login_as(@user)

    get explore_bosnia_experience_path(@history.key)

    assert_select "[data-plan-deck-target='card'][data-plan-deck-visited='true']", count: 1
  end

  test "the hidden plan never appears in the profile plan list" do
    login_as(@user)
    get explore_bosnia_experience_path(@history.key)

    get travel_profile_path

    assert_response :success
    refute_includes response.body, "Explore Bosnia</h3>"
    assert_not_includes Plan.without_explore_bosnia.where(user: @user), Plan.explore_bosnia_for(@user)
  end

  private

  def login_as(user)
    post login_path, params: { username: user.username, password: "password123" }
  end
end
