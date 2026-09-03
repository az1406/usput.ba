# frozen_string_literal: true

require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @location = Location.create!(name: "Event Loc", city: "Sarajevo", lat: 43.8563, lng: 18.4131)
    @upcoming = Event.create!(title: "Upcoming Event", starts_at: 5.days.from_now, duration: 120, description: "desc", location: @location)
    @past = Event.create!(title: "Past Event", starts_at: 5.days.ago, duration: 60, location: @location)
  end

  teardown do
    Event.destroy_all
    @location&.destroy
  end

  test "index renders and lists events" do
    get events_path
    assert_response :success
    assert_select "h1"
    assert_match @upcoming.title, response.body
    assert_match @past.title, response.body
  end

  test "index filters by city" do
    elsewhere = Location.create!(name: "Mostar Loc", city: "Mostar", lat: 43.3438, lng: 17.8078)
    other_city = Event.create!(title: "Mostar Event", starts_at: 3.days.from_now, location: elsewhere)

    get events_path(city: "Sarajevo")

    assert_response :success
    assert_match @upcoming.title, response.body
    assert_no_match other_city.title, response.body
  ensure
    other_city&.destroy
    elsewhere&.destroy
  end

  test "the city filter narrows past events too" do
    elsewhere = Location.create!(name: "Mostar Loc", city: "Mostar", lat: 43.3438, lng: 17.8078)
    other_city_past = Event.create!(title: "Mostar Past Event", starts_at: 6.days.ago, location: elsewhere)

    get events_path(city: "Sarajevo")

    assert_response :success
    assert_match @past.title, response.body
    assert_no_match other_city_past.title, response.body
  ensure
    other_city_past&.destroy
    elsewhere&.destroy
  end

  test "index keeps events held at a retired place" do
    @location.archive!

    get events_path

    assert_response :success
    assert_match @upcoming.title, response.body
    assert_match @past.title, response.body
  end

  test "show keeps an event held at a retired place" do
    @location.archive!

    get event_path(@upcoming)

    assert_response :success
    assert_select "h1", /Upcoming Event/
  end

  test "show renders an event by uuid" do
    get event_path(@upcoming)
    assert_response :success
    assert_select "h1", /Upcoming Event/
  end

  test "show redirects to index for unknown event" do
    get event_path("nonexistent-uuid")
    assert_redirected_to events_path
  end

  test "show renders the venue map" do
    get event_path(@upcoming)
    assert_select "[data-controller=map] [data-map-target=container]", 1
  end

  test "show reads the event in the request's locale" do
    @upcoming.set_translation(:title, "Bevorstehende Veranstaltung", :de)
    get event_path(@upcoming), params: { locale: :de }
    assert_match "Bevorstehende Veranstaltung", response.body
    assert_no_match "Upcoming Event", response.body
  end
end
