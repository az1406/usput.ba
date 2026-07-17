# frozen_string_literal: true

require "test_helper"

# The "start a plan" walk: a plan renders its locations as steps. A step starts
# as "I was here"; marking it visited persists (server-owned, per-user) and
# swaps in the moment capture. Progress survives leaving and returning.
class PlanStartTest < ActionDispatch::IntegrationTest
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

  test "the plan page links to the start walk" do
    login_as(@user)

    get plan_path(@plan)

    assert_response :success
    assert_select "a[href=?]", start_plan_path(@plan), count: 1
  end

  test "an unvisited step offers to mark visited, with no capture yet" do
    login_as(@user)

    get start_plan_path(@plan)

    assert_response :success
    assert_select "form[action=?]", plan_visits_path(@plan), count: @plan.all_locations.size
    assert_select "form[action=?]", plan_moments_path(@plan), count: 0
  end

  test "marking a step visited persists it and reveals the capture" do
    login_as(@user)

    post plan_visits_path(@plan), params: { location_id: @location.uuid }, as: :turbo_stream

    assert_response :success
    assert @user.plan_visits.exists?(plan: @plan, location: @location), "the visit must be recorded"
    assert_select "turbo-stream[action=replace][target=?]", ActionView::RecordIdentifier.dom_id(@location, :step)
    assert_includes response.body, plan_moments_path(@plan), "the revealed capture posts to moments"
  end

  test "visited progress survives leaving and returning to the walk" do
    @user.plan_visits.create!(plan: @plan, location: @location)
    login_as(@user)

    get start_plan_path(@plan)

    assert_response :success
    assert_select "form[action=?]", plan_visits_path(@plan), count: 0, msg: "already visited, so no I-was-here form"
    assert_select "form[action=?]", plan_moments_path(@plan), count: 1, msg: "the capture is present for the visited step"
  end

  test "capturing a photo on the walk adds it and shows it on the step" do
    login_as(@user)

    post plan_moments_path(@plan), params: {
      moment: {
        location_id: @location.uuid,
        photo: fixture_file_upload("test/fixtures/files/real_image.jpg", "image/jpeg")
      }
    }

    assert_equal 1, @user.moments.where(plan: @plan, location: @location).count

    get start_plan_path(@plan)

    assert_response :success
    assert_select "img[src=?]",
      photo_plan_moment_path(@plan, @user.moments.where(plan: @plan).last, size: "thumb"),
      count: 1
  end

  test "a guest walking a public plan is asked to log in, not to capture" do
    @plan.update!(visibility: :public_plan)

    get start_plan_path(@plan)

    assert_response :success
    assert_select "form[action=?]", plan_visits_path(@plan), count: 0
    assert_select "form[action=?]", plan_moments_path(@plan), count: 0
  end

  test "a guest cannot walk a private plan" do
    get start_plan_path(@plan)

    assert_redirected_to "/explore"
  end

  private

  def login_as(user)
    post login_path, params: { username: user.username, password: "password123" }
  end
end
