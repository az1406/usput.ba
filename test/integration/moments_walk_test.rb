# frozen_string_literal: true

require "test_helper"

# The moments UI is only reachable if three separate pages agree: the profile
# carries the passport button, the plan card links to the server-rendered plan
# page (not the localStorage viewer), and that page renders the upload form.
# Any one of them drifting makes the feature invisible without failing a unit test.
class MomentsWalkTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "walker", password: "password123")
    @location = Location.create!(name: "Walk Loc", city: "Sarajevo", lat: 43.85, lng: 18.41)
    @experience = Experience.create!(title: "Walk Exp", description: "desc")
    @experience.locations << @location
    @plan = Plan.create!(title: "Walk Plan", city_name: "Sarajevo", visibility: :private_plan, user: @user)
    @plan.plan_experiences.create!(experience: @experience, day_number: 1)
  end

  teardown do
    @plan&.destroy
    @experience&.destroy
    @location&.destroy
    @user&.destroy
  end

  test "the profile page carries the passport button" do
    login_as(@user)

    get profile_page_path

    assert_response :success
    assert_select "[data-controller='passport'] button[data-passport-target='printButton']", count: 1
  end

  test "the profile page lists the traveller's moments grouped by trip" do
    add_moment(note: "Sunset over the bridge")
    login_as(@user)

    get profile_page_path

    assert_response :success
    assert_select "img[alt=?]", "Sunset over the bridge", { minimum: 1 }, "the moment photo must render on the profile"
    assert_select "a[href=?]", start_plan_path(@plan), { minimum: 1 }, "moments are grouped under their trip, linking into the walk"
  end

  test "a plan card links to the plan page where moments live" do
    login_as(@user)

    # Cards are lazy-loaded into a turbo-frame, so they are not in the profile HTML
    get profile_plans_path

    assert_response :success
    assert_select "a[href=?]", plan_path(@plan), count: 1
  end

  test "the plan page renders an upload form for each location on the plan" do
    login_as(@user)

    get plan_path(@plan)

    assert_response :success
    assert_select "form[action=?]", plan_moments_path(@plan), count: @plan.all_locations.size
    assert_select "input[type=file][name=?]", "moment[photo]", count: @plan.all_locations.size
  end

  test "a guest sees no moments section on a public plan" do
    @plan.update!(visibility: :public_plan)

    get plan_path(@plan)

    assert_response :success
    assert_select "form[action=?]", plan_moments_path(@plan), count: 0
  end

  test "the walk offers to share a private moment" do
    add_moment(note: "shareable")
    login_as(@user)

    get start_plan_path(@plan)

    assert_response :success
    assert_select "form[action=?]", publish_plan_moment_path(@plan, @user.moments.first)
  end

  test "the walk offers to unshare an already-public moment" do
    add_moment(note: "shared").update!(visibility: :public_moment)
    login_as(@user)

    get start_plan_path(@plan)

    assert_response :success
    assert_select "form[action=?]", unpublish_plan_moment_path(@plan, @user.moments.first)
  end

  test "marking a location visited within 100m records the visit" do
    login_as(@user)

    assert_difference -> { @user.plan_visits.count }, 1 do
      post plan_visits_path(@plan), params: { location_id: @location.uuid, user_lat: @location.lat, user_lng: @location.lng }
    end
  end

  test "marking a location visited from too far away is rejected with an alert" do
    login_as(@user)

    assert_no_difference -> { @user.plan_visits.count } do
      post plan_visits_path(@plan), params: { location_id: @location.uuid, user_lat: 43.90, user_lng: 18.50 }
    end
    assert flash[:alert].present?, "a too-far visit must surface an alert"
  end

  test "marking a location visited without coordinates is rejected" do
    login_as(@user)

    assert_no_difference -> { @user.plan_visits.count } do
      post plan_visits_path(@plan), params: { location_id: @location.uuid, user_lat: 0, user_lng: 0 }
    end
  end

  private

  def login_as(user)
    post login_path, params: { username: user.username, password: "password123" }
  end

  def add_moment(note: nil)
    moment = @user.moments.build(plan: @plan, location: @location, note: note)
    moment.photo.attach(
      io: File.open("test/fixtures/files/test_image.jpg"),
      filename: "moment.jpg",
      content_type: "image/jpeg"
    )
    moment.save!
    moment
  end
end
