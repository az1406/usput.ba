# frozen_string_literal: true

require "test_helper"

# Explore Bosnia: six fixed tiles, each grouping several experience types, deal
# the closest unvisited places as walk cards. Check-ins and moments ride a
# hidden per-user plan that never surfaces in plan listings.
class ExploreBosniaTest < ActionDispatch::IntegrationTest
  SARAJEVO = { lat: 43.85, lng: 18.41 }.freeze

  setup do
    @user = User.create!(username: "wanderer", password: "password123")
    # Canonical keys: the "history" tile groups the "history" type.
    @history = ExperienceType.create!(key: "history", name: "History", active: true)
    @near = Location.create!(name: "Close Fort", city: "Sarajevo", lat: 43.85, lng: 18.41,
                             suitable_experiences: [ @history.key ])
    @mid = Location.create!(name: "Middle Fort", city: "Visoko", lat: 43.65, lng: 18.20,
                            suitable_experiences: [ @history.key ])
    # ~75 km out: beyond RADIUS_KM, so the cap can be asserted.
    @outside = Location.create!(name: "Far Fort", city: "Mostar", lat: 43.34, lng: 17.81,
                                suitable_experiences: [ @history.key ])
  end

  teardown do
    [ @near, @mid, @outside ].each { |location| location&.destroy }
    @history&.destroy
    @user&.plans&.destroy_all
    @user&.destroy
    @admin&.plans&.destroy_all
    @admin&.destroy
  end

  test "the grid shows the six browse tiles" do
    get explore_bosnia_path

    assert_response :success
    assert_select "[data-explore-geo-target='tile']", count: 6
    assert_select "a[href=?]", explore_bosnia_experience_path("history"), count: 1
    assert_select "a[href=?]", explore_bosnia_experience_path("relax"), count: 1
  end

  test "an unknown tile falls back to the grid" do
    login_as(@user)

    get explore_bosnia_experience_path("not-a-tile", **SARAJEVO)

    assert_redirected_to explore_bosnia_path
  end

  test "the experience deck requires login" do
    get explore_bosnia_experience_path("history")

    assert_redirected_to login_path
  end

  test "without coordinates the deck asks for location instead of dealing" do
    login_as(@user)

    get explore_bosnia_experience_path("history")

    assert_response :success
    assert_includes response.body, I18n.t("explore_bosnia.needs_location.title")
    assert_select "[data-plan-deck-target='card']", count: 0
  end

  test "the deck renders scrollable cards with the swipe hint" do
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    assert_select "[data-plan-deck-target='card']", count: 2
    assert_select "[data-plan-deck-target='hint']", count: 2
  end

  test "the cards are closest first with a distance" do
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    assert_operator response.body.index("Close Fort"), :<, response.body.index("Middle Fort")
    assert_includes response.body, "km"
  end

  test "places beyond the radius are not dealt" do
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    refute_includes response.body, "Far Fort"
  end

  test "a visitor with nothing in range gets the empty deck" do
    login_as(@user)

    get explore_bosnia_experience_path("history", lat: 52.52, lng: 13.40)

    assert_response :success
    assert_select "[data-plan-deck-target='card']", count: 0
    assert_includes response.body, I18n.t("explore_bosnia.deck_empty")
  end

  test "a tile deals every one of its member types" do
    art = ExperienceType.create!(key: "art", name: "Art", active: true)
    culture = ExperienceType.create!(key: "culture", name: "Culture", active: true)
    gallery = Location.create!(name: "City Gallery", city: "Sarajevo", lat: 43.856, lng: 18.412,
                               suitable_experiences: [ art.key ])
    museum = Location.create!(name: "City Museum", city: "Sarajevo", lat: 43.857, lng: 18.413,
                              suitable_experiences: [ culture.key ])
    login_as(@user)

    get explore_bosnia_experience_path("culture", **SARAJEVO)

    assert_response :success
    assert_includes response.body, "City Gallery"
    assert_includes response.body, "City Museum"
  ensure
    [ gallery, museum ].each { |location| location&.destroy }
    [ art, culture ].each { |type| type&.destroy }
  end

  test "a location carrying two of a tile's types is dealt once" do
    art = ExperienceType.create!(key: "art", name: "Art", active: true)
    culture = ExperienceType.create!(key: "culture", name: "Culture", active: true)
    both = Location.create!(name: "Double Tagged", city: "Sarajevo", lat: 43.856, lng: 18.412,
                            suitable_experiences: [ art.key, culture.key ])
    login_as(@user)

    get explore_bosnia_experience_path("culture", **SARAJEVO)

    assert_response :success
    assert_select "[data-plan-deck-target='card']", count: 1
  ensure
    both&.destroy
    [ art, culture ].each { |type| type&.destroy }
  end

  test "a page never deals more than PAGE_SIZE places" do
    12.times do |i|
      Location.create!(name: "Spot #{i}", city: "Sarajevo", lat: 43.8 + i * 0.001, lng: 18.4,
                       suitable_experiences: [ @history.key ])
    end
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    assert_select "[data-plan-deck-target='card']", count: ExploreBosniaController::PAGE_SIZE
  ensure
    Location.where("name LIKE 'Spot %'").destroy_all
  end

  test "a full page offers the next one as a lazy frame" do
    12.times do |i|
      Location.create!(name: "Spot #{i}", city: "Sarajevo", lat: 43.8 + i * 0.001, lng: 18.4,
                       suitable_experiences: [ @history.key ])
    end
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    assert_select "turbo-frame#explore_page_2[loading='lazy']", count: 1
  ensure
    Location.where("name LIKE 'Spot %'").destroy_all
  end

  test "the last page ends the reel instead of offering another" do
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    assert_select "turbo-frame#explore_page_2", count: 0
    assert_includes response.body, I18n.t("explore_bosnia.deck_end")
  end

  test "the second page deals the places the first one did not" do
    12.times do |i|
      Location.create!(name: "Spot #{i}", city: "Sarajevo", lat: 43.8 + i * 0.001, lng: 18.4,
                       suitable_experiences: [ @history.key ])
    end
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO, page: 2)

    assert_response :success
    assert_select "[data-plan-deck-target='card']", count: 4
  ensure
    Location.where("name LIKE 'Spot %'").destroy_all
  end

  # Bullet is blind to find_by-on-a-loaded-association, which is how the
  # translate/primary_category N+1 hides, so the count is asserted directly.
  test "the deck's query count does not grow with the number of cards" do
    login_as(@user)
    get explore_bosnia_experience_path("history", **SARAJEVO) # warm the caches

    two_cards = count_queries { get explore_bosnia_experience_path("history", **SARAJEVO) }

    8.times do |i|
      Location.create!(name: "Spot #{i}", city: "Sarajevo", lat: 43.8 + i * 0.001, lng: 18.4,
                       suitable_experiences: [ @history.key ])
    end

    ten_cards = count_queries { get explore_bosnia_experience_path("history", **SARAJEVO) }

    assert_select "[data-plan-deck-target='card']", count: 10
    marginal = (ten_cards - two_cards) / 8.0
    # ~4 is the known translate/primary_category cost; Translatable is inherited
    # code we work around rather than edit, and paging bounds it to one page.
    # Anything above that is a new N+1.
    assert_operator marginal, :<=, 5,
      "each extra card costs #{marginal.round(1)} queries (#{two_cards} -> #{ten_cards})"
  ensure
    Location.where("name LIKE 'Spot %'").destroy_all
  end

  test "the reel ships no moments until a panel is opened" do
    moment = @user.moments.new(plan: Plan.explore_bosnia_for(@user), location: @near, visibility: :private_moment)
    moment.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/real_image.jpg")), filename: "real_image.jpg", content_type: "image/jpeg")
    moment.save!
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    assert_select "turbo-frame[id=?][loading='lazy']",
                  ActionView::RecordIdentifier.dom_id(@near, :moments_frame), count: 1
    refute_includes response.body, photo_plan_moment_path(moment.plan, moment, size: "thumb")
  end

  test "the moments frame renders the gallery for its location" do
    moment = @user.moments.new(plan: Plan.explore_bosnia_for(@user), location: @near, visibility: :private_moment)
    moment.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/real_image.jpg")), filename: "real_image.jpg", content_type: "image/jpeg")
    moment.save!
    login_as(@user)

    get plan_moments_path(moment.plan, location_id: @near.uuid, context: "explore"),
        headers: { "Turbo-Frame" => ActionView::RecordIdentifier.dom_id(@near, :moments_frame) }

    assert_response :success
    assert_select "img[src=?]", photo_plan_moment_path(moment.plan, moment, size: "thumb"), count: 1
    assert_select "[data-photo-gallery-full-url=?]",
                  photo_plan_moment_path(moment.plan, moment, size: "story"), count: 1
    assert_select "form[action=?]", publish_plan_moment_path(moment.plan, moment), count: 1
  end

  test "a tile whose places are all visited says so, not that it is empty" do
    plan = Plan.create!(title: "Trip", visibility: :private_plan, user: @user)
    [ @near, @mid ].each { |location| @user.plan_visits.create!(plan: plan, location: location) }
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    assert_includes response.body, I18n.t("explore_bosnia.deck_all_visited")
    refute_includes response.body, I18n.t("explore_bosnia.deck_empty")
  end

  test "a tile with no places at all still says it is empty" do
    login_as(@user)

    get explore_bosnia_experience_path("relax", **SARAJEVO)

    assert_response :success
    assert_includes response.body, I18n.t("explore_bosnia.deck_empty")
  end

  test "a location visited on any plan is not dealt again" do
    other_plan = Plan.create!(title: "Trip", visibility: :private_plan, user: @user)
    @user.plan_visits.create!(plan: other_plan, location: @near)
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    refute_includes response.body, "Close Fort"
    assert_includes response.body, "Middle Fort"
  end

  test "the moments panel offers upload and badges a private moment" do
    plan = Plan.explore_bosnia_for(@user)
    @user.plan_visits.create!(plan: plan, location: @near) # capture is earned by being there
    moment = @user.moments.new(plan: plan, location: @near, visibility: :private_moment)
    moment.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/real_image.jpg")), filename: "real_image.jpg", content_type: "image/jpeg")
    moment.save!
    login_as(@user)

    get plan_moments_path(moment.plan, location_id: @near.uuid, context: "explore"),
        headers: { "Turbo-Frame" => ActionView::RecordIdentifier.dom_id(@near, :moments_frame) }

    assert_response :success
    assert_select "label[aria-label=?]", I18n.t("plans.moments.add"), minimum: 1
    assert_includes response.body, I18n.t("plans.start.story_private")
    assert_select "form[action=?]", publish_plan_moment_path(moment.plan, moment), count: 1
  end

  test "the moments panel withholds upload until the place is visited" do
    login_as(@user)

    get plan_moments_path(Plan.explore_bosnia_for(@user), location_id: @near.uuid, context: "explore"),
        headers: { "Turbo-Frame" => ActionView::RecordIdentifier.dom_id(@near, :moments_frame) }

    assert_response :success
    assert_select "label[aria-label=?]", I18n.t("plans.moments.add"), count: 0
  end

  test "the moments panel shows another traveller's approved public moment" do
    other = User.create!(username: "other_wanderer", password: "password123")
    moment = other.moments.new(plan: Plan.explore_bosnia_for(other), location: @near, visibility: :public_moment)
    moment.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/real_image.jpg")), filename: "real_image.jpg", content_type: "image/jpeg")
    moment.save!
    moment.update!(moderation_status: :approved)
    login_as(@user)

    get plan_moments_path(Plan.explore_bosnia_for(@user), location_id: @near.uuid, context: "explore"),
        headers: { "Turbo-Frame" => ActionView::RecordIdentifier.dom_id(@near, :moments_frame) }

    assert_response :success
    assert_select "[data-photo-gallery-target='thumbnail']", count: 1
  ensure
    other&.moments&.destroy_all
    other&.plans&.destroy_all
    other&.destroy
  end

  test "an own approved public moment removes the be-first invitation" do
    moment = @user.moments.new(plan: Plan.explore_bosnia_for(@user), location: @near,
                               visibility: :public_moment)
    moment.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/real_image.jpg")), filename: "real_image.jpg", content_type: "image/jpeg")
    moment.save!
    moment.update!(moderation_status: :approved) # the curator's approval
    login_as(@user)

    plan = Plan.explore_bosnia_for(@user)
    frame = ->(location) do
      get plan_moments_path(plan, location_id: location.uuid, context: "explore"),
          headers: { "Turbo-Frame" => ActionView::RecordIdentifier.dom_id(location, :moments_frame) }
      response.body
    end

    refute_includes frame.call(@near), I18n.t("plans.start.story_none")
    assert_includes frame.call(@mid), I18n.t("plans.start.story_none")
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

  test "the card ships a lazy reviews frame rather than the reviews themselves" do
    Review.create!(reviewable: @near, rating: 5, comment: "Amazing fortress views", author_name: "Mira")
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    assert_select "turbo-frame[id=?][loading='lazy']",
                  ActionView::RecordIdentifier.dom_id(@near, :reviews_frame), count: 1
    refute_includes response.body, "Amazing fortress views"
  end

  test "the reviews frame renders the scoped section with its form" do
    Review.create!(reviewable: @near, rating: 5, comment: "Amazing fortress views", author_name: "Mira")
    login_as(@user)

    get location_reviews_path(@near),
        headers: { "Turbo-Frame" => ActionView::RecordIdentifier.dom_id(@near, :reviews_frame) }

    assert_response :success
    assert_includes response.body, "Amazing fortress views"
    assert_select "##{ActionView::RecordIdentifier.dom_id(@near, :reviews_section)}", count: 1
    assert_select "form[action=?]", location_reviews_path(@near), minimum: 1
  end

  test "submitting a review from the explore panel creates it and streams the scoped section back" do
    login_as(@user)

    assert_difference -> { @near.reviews.count }, 1 do
      post location_reviews_path(@near),
           params: { review: { rating: 5, comment: "Prelijepo mjesto", author_name: "Amela" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_match ActionView::RecordIdentifier.dom_id(@near, :reviews_section), response.body
    assert_includes response.body, "Prelijepo mjesto"
  end

  test "opening a deck creates the hidden plan and check-ins land on it" do
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)
    hidden_plan = Plan.explore_bosnia_for(@user)

    assert_select "form[action=?]", plan_visits_path(hidden_plan), count: 2

    post plan_visits_path(hidden_plan),
         params: { location_id: @near.uuid, user_lat: 43.85, user_lng: 18.41 },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert hidden_plan.plan_visits.exists?(user: @user, location: @near)
  end

  test "the hidden plan never appears in the profile plan list" do
    login_as(@user)
    get explore_bosnia_experience_path("history", **SARAJEVO)

    get travel_profile_path

    assert_response :success
    refute_includes response.body, "Explore Bosnia</h3>"
    assert_not_includes Plan.without_explore_bosnia.where(user: @user), Plan.explore_bosnia_for(@user)
  end

  test "the check-in hint carries the localized cold-warm scale and enable-location text" do
    login_as(@user)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    assert_select "[data-geo-visit-target='hint'][data-warmth=?]", I18n.t("plans.start.warmth"), minimum: 1
    assert_select "[data-geo-visit-target='hint'][data-enable-location=?]", I18n.t("plans.start.need_location"), minimum: 1
  end

  test "an admin is dealt places beyond the radius" do
    login_as(admin)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    assert_includes response.body, "Far Fort"
  end

  test "an admin who never answered the location prompt is still dealt the walk" do
    login_as(admin)

    get explore_bosnia_experience_path("history")

    assert_response :success
    assert_includes response.body, "Close Fort"
  end

  test "an admin checks in with a plain submit, not the distance-gated one" do
    login_as(admin)

    get explore_bosnia_experience_path("history", **SARAJEVO)

    assert_response :success
    assert_select "[data-controller='geo-visit']", count: 0
  end

  test "an admin check-in from nowhere near the place records the visit" do
    admin_user = admin
    login_as(admin_user)
    get explore_bosnia_experience_path("history", **SARAJEVO)
    hidden_plan = Plan.explore_bosnia_for(admin_user)

    post plan_visits_path(hidden_plan),
         params: { location_id: @near.uuid, user_lat: 0, user_lng: 0 }, as: :turbo_stream

    assert_response :success
    assert admin_user.plan_visits.exists?(plan: hidden_plan, location: @near),
           "the admin bypass must record the visit"
  end

  private

  def admin
    @admin ||= User.create!(username: "chief", password: "password123", user_type: :admin)
  end

  def login_as(user)
    post login_path, params: { username: user.username, password: "password123" }
  end

  def count_queries
    count = 0
    counter = ->(_name, _start, _finish, _id, payload) do
      count += 1 unless payload[:name] == "SCHEMA" || payload[:cached]
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end
end
