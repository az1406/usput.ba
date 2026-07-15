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
  end

  test "index filters by city" do
    get events_path(city: "Sarajevo")
    assert_response :success
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
end
