require "application_system_test_case"

# The explore browse deck in a real browser: swipe right checks in, tapping the
# card opens the menu, and the moments panel gates on the visit.
class ExploreBosniaSystemTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(username: "sys_explorer", password: "password123")
    @type = ExperienceType.create!(key: "history", name: "Sys History", active: true)
    @location = Location.create!(name: "Sys Fort", city: "Sarajevo", lat: 43.85, lng: 18.41,
                                 suitable_experiences: [ @type.key ])
    @location.photos.attach(io: File.open(Rails.root.join("test/fixtures/files/real_image.jpg")),
                            filename: "real_image.jpg", content_type: "image/jpeg")
  end

  teardown do
    @location&.destroy
    @type&.destroy
    @user&.plans&.destroy_all
    @user&.destroy
  end

  def login
    visit login_path
    within "form" do
      fill_in "username", with: "sys_explorer"
      fill_in "password", with: "password123"
      click_button
    end
    assert_no_current_path login_path, wait: 5
  end

  # The deck refuses to deal without coordinates, so they ride the path the way
  # the grid's tile links supply them.
  def visit_deck
    visit explore_bosnia_experience_path("history", lat: @location.lat, lng: @location.lng)
  end

  # Same CDP override the walk's system test uses.
  def stand_at(location)
    uri = URI.parse(page.current_url)
    browser = page.driver.browser
    browser.execute_cdp("Browser.grantPermissions", origin: "#{uri.scheme}://#{uri.host}:#{uri.port}", permissions: [ "geolocation" ])
    browser.execute_cdp("Emulation.setGeolocationOverride", latitude: location.lat.to_f, longitude: location.lng.to_f, accuracy: 5)
  end

  def swipe_card(dx:)
    page.execute_script(<<~JS, dx)
      const dx = arguments[0]
      const el = document.querySelector("[data-plan-deck-target='card']")
      const fire = (type, x) => el.dispatchEvent(new PointerEvent(type, {
        pointerId: 1, isPrimary: true, pointerType: "touch",
        clientX: x, clientY: 20, bubbles: true, cancelable: true
      }))
      fire("pointerdown", 200)
      fire("pointerup", 200 + dx)
    JS
  end

  test "swiping right on the card checks in and stamps it visited" do
    login
    visit explore_bosnia_path
    stand_at(@location)
    visit_deck

    swipe_card(dx: 120)

    assert_text "Visited", wait: 5
    assert @user.plan_visits.joins(:plan).exists?(location: @location)
  end

  test "tapping the card opens the menu; moments stay locked before a visit" do
    login
    visit_deck

    find("[data-plan-deck-target='card']").click
    assert_selector "[data-card-menu-target='menu']", visible: true, wait: 5

    swipe_card(dx: -120)
    assert_no_selector "[data-card-menu-target='panel'][data-panel='moments']", visible: true
  end

  test "after a visit, swipe left opens the moments panel with the upload tile" do
    login
    visit explore_bosnia_path
    stand_at(@location)
    visit_deck
    swipe_card(dx: 120)
    assert_text "Visited", wait: 5

    swipe_card(dx: -120)

    assert_selector "[data-card-menu-target='panel'][data-panel='moments']", visible: true, wait: 5
    assert_selector "p", text: I18n.t("plans.start.story_none"), visible: :all
    assert_selector "label[aria-label='#{I18n.t('plans.moments.add')}']", visible: :all
  end
end
