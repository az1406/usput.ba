require "application_system_test_case"

class PlanWalkTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(username: "sys_walker", password: "password123")
    @location = Location.create!(name: "Sys Loc", city: "Sarajevo", lat: 43.85, lng: 18.41)
    @experience = Experience.create!(title: "Sys Exp", description: "desc")
    @experience.locations << @location
    @plan = Plan.create!(title: "Sys Plan", city_name: "Sarajevo", visibility: :private_plan, user: @user)
    @plan.plan_experiences.create!(experience: @experience, day_number: 1)
  end

  def swipe_right_on(selector)
    swipe_on(selector, dx: 120, dy: 0)
  end

  # Real TouchEvents — Capybara cannot express a finger, and the controller
  # listens for touchstart/touchend only.
  def swipe_on(selector, dx:, dy:)
    page.execute_script(<<~JS, selector, dx, dy)
      const [selector, dx, dy] = arguments
      const el = document.querySelector(selector)
      const startX = 20, startY = 20

      const touch = (x, y) => new Touch({ identifier: 1, target: el, clientX: x, clientY: y })
      const fire = (type, x, y, ending) => el.dispatchEvent(new TouchEvent(type, {
        touches: ending ? [] : [touch(x, y)],
        changedTouches: [touch(x, y)],
        bubbles: true,
        cancelable: true
      }))

      fire("touchstart", startX, startY, false)
      fire("touchend", startX + dx, startY + dy, true)
    JS
  end

  def login
    visit login_path
    within "form" do
      fill_in "username", with: "sys_walker"
      fill_in "password", with: "password123"
      click_button
    end
    assert_no_current_path login_path, wait: 5
  end

  # Put the headless browser at a real position so the geo-visit check passes —
  # the same override DevTools' Sensors panel applies by hand.
  def stand_at(location)
    uri = URI.parse(page.current_url)
    browser = page.driver.browser
    browser.execute_cdp("Browser.grantPermissions", origin: "#{uri.scheme}://#{uri.host}:#{uri.port}", permissions: [ "geolocation" ])
    browser.execute_cdp("Emulation.setGeolocationOverride", latitude: location.lat.to_f, longitude: location.lng.to_f, accuracy: 5)
  end

  test "mark visited then drop a photo, both appear without a reload" do
    login
    visit start_plan_path(@plan)
    stand_at(@location)

    click_button "I was here"
    assert_text "Visited", wait: 5

    attach_file "moment[photo]", file_fixture("real_image.jpg").to_s, make_visible: true

    assert_selector "img[src*='/moments/']", wait: 5
  end

  test "swiping a step right marks it visited" do
    login
    visit start_plan_path(@plan)
    stand_at(@location)

    assert_no_text "Visited"
    swipe_right_on "##{ActionView::RecordIdentifier.dom_id(@location, :step)}"

    assert_text "Visited", wait: 5
    assert @user.plan_visits.exists?(plan: @plan, location: @location), "the swipe must persist the visit"
  end

  test "swiping a step down does not mark it visited" do
    login
    visit start_plan_path(@plan)
    stand_at(@location)

    swipe_on "##{ActionView::RecordIdentifier.dom_id(@location, :step)}", dx: 0, dy: 120

    assert_no_text "Visited"
    assert_not @user.plan_visits.exists?(plan: @plan, location: @location), "a vertical scroll is not a swipe"
  end

  test "visited progress persists when leaving and returning to the walk" do
    login
    visit start_plan_path(@plan)
    stand_at(@location)
    click_button "I was here"
    assert_text "Visited", wait: 5

    visit plan_path(@plan)
    visit start_plan_path(@plan)

    assert_text "Visited"
  end
end
