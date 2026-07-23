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

  # Real PointerEvents — Capybara cannot express a drag gesture, and the
  # controller listens for pointerdown/pointerup (finger and mouse alike).
  def swipe_on(selector, dx:, dy:)
    page.execute_script(<<~JS, selector, dx, dy)
      const [selector, dx, dy] = arguments
      const el = document.querySelector(selector)
      const startX = 20, startY = 20

      const fire = (type, x, y) => el.dispatchEvent(new PointerEvent(type, {
        pointerId: 1,
        isPrimary: true,
        pointerType: "touch",
        clientX: x,
        clientY: y,
        bubbles: true,
        cancelable: true
      }))

      fire("pointerdown", startX, startY)
      fire("pointerup", startX + dx, startY + dy)
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

  test "the deck opens on the location closest to me, not plan order" do
    far = Location.create!(name: "Far Loc", city: "Sarajevo", lat: 43.90, lng: 18.50)
    @experience.locations << far
    login
    stand_at(far)
    visit start_plan_path(@plan)

    assert_selector "##{ActionView::RecordIdentifier.dom_id(far, :step)}", visible: true, wait: 5
    assert_no_selector "##{ActionView::RecordIdentifier.dom_id(@location, :step)}", visible: true
  ensure
    far&.destroy
  end

  test "returning to the walk resumes at the next un-visited stop" do
    second = Location.create!(name: "Second Loc", city: "Sarajevo", lat: 43.86, lng: 18.42)
    @experience.locations << second
    @user.plan_visits.create!(plan: @plan, location: @location)
    login
    visit start_plan_path(@plan)

    assert_selector "##{ActionView::RecordIdentifier.dom_id(second, :step)}", visible: true, wait: 5
    assert_no_selector "##{ActionView::RecordIdentifier.dom_id(@location, :step)}", visible: true
  ensure
    second&.destroy
  end

  test "publishing a moment from the profile updates in place (no full reload)" do
    moment = @user.moments.build(plan: @plan, location: @location)
    moment.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/real_image.jpg")), filename: "m.jpg", content_type: "image/jpeg")
    moment.save!
    login
    visit profile_page_path

    frame = "##{ActionView::RecordIdentifier.dom_id(moment)}"
    within(frame) { find("button[type=submit]").click }

    assert_selector "#{frame} form[action='#{unpublish_plan_moment_path(@plan, moment)}']", wait: 5
    assert moment.reload.visibility_public_moment?, "the moment must be public after publishing"
  end

  test "with the geofence off, a single click marks the location visited" do
    ENV["SKIP_GEOFENCE"] = "true"
    login
    visit start_plan_path(@plan)

    click_button "Check if I'm here"

    assert_text "Visited", wait: 5
  ensure
    ENV.delete("SKIP_GEOFENCE")
  end

  test "mark visited then drop a photo in the stories, it appears without a reload" do
    login
    visit start_plan_path(@plan)
    stand_at(@location)

    click_button "Check if I'm here"
    assert_text "Visited", wait: 5

    swipe_on "[data-plan-deck-target='card']", dx: -120, dy: 0
    assert_selector "dialog[open][data-story-viewer-target='overlay']", visible: :all, wait: 5

    # The + button opens a native picker Capybara can't drive; unhide the
    # upload form it fronts and attach directly.
    page.execute_script("document.querySelector('[data-story-upload]').classList.remove('hidden')")
    attach_file "moment[photo]", file_fixture("real_image.jpg").to_s, make_visible: true

    assert_selector "img[src*='/moments/']", visible: :all, wait: 5
  end

  test "an un-visited card cannot be swiped past" do
    login
    visit start_plan_path(@plan)

    step = "##{ActionView::RecordIdentifier.dom_id(@location, :step)}"
    swipe_right_on step

    assert_selector step, visible: true # must check in before moving on
  end

  test "after checking in, swiping the card right advances past it" do
    login
    visit start_plan_path(@plan)
    stand_at(@location)
    click_button "Check if I'm here"
    assert_text "Visited", wait: 5

    swipe_right_on "##{ActionView::RecordIdentifier.dom_id(@location, :step)}"

    assert_no_selector "##{ActionView::RecordIdentifier.dom_id(@location, :step)}", visible: true, wait: 5
  end

  test "visited progress persists when leaving and returning to the walk" do
    login
    visit start_plan_path(@plan)
    stand_at(@location)
    click_button "Check if I'm here"
    assert_text "Visited", wait: 5

    visit plan_path(@plan)
    visit start_plan_path(@plan)

    assert_text "Visited"
  end
end
