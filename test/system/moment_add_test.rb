require "application_system_test_case"

class MomentAddTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(username: "sys_walker", password: "password123")
    @location = Location.create!(name: "Sys Loc", city: "Sarajevo", lat: 43.85, lng: 18.41)
    @experience = Experience.create!(title: "Sys Exp", description: "desc")
    @experience.locations << @location
    @plan = Plan.create!(title: "Sys Plan", city_name: "Sarajevo", visibility: :private_plan, user: @user)
    @plan.plan_experiences.create!(experience: @experience, day_number: 1)
  end

  test "a moment photo appears on the plan panel without a reload" do
    visit login_path
    within "form" do
      fill_in "username", with: "sys_walker"
      fill_in "password", with: "password123"
      click_button
    end
    assert_no_current_path login_path, wait: 5

    visit plan_path(@plan)

    find("button[data-moments-panel-target='button']").click
    attach_file "moment[photo]", file_fixture("real_image.jpg").to_s, make_visible: true
    find("input[type=submit][value='Add']").click

    assert_selector "img[src*='/moments/']", wait: 5
  end
end
