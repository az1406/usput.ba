# frozen_string_literal: true

require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @location = Location.create!(
      name: "Event Location",
      city: "Sarajevo",
      lat: 43.8563,
      lng: 18.4131
    )
  end

  teardown do
    @location&.destroy
  end

  test "valid event is saved" do
    event = Event.new(title: "Concert", starts_at: 2.days.from_now, location: @location)
    assert event.save
    event.destroy
  end

  test "title is required" do
    event = Event.new(starts_at: 2.days.from_now, location: @location)
    assert_not event.valid?
    assert_includes event.errors[:title], "can't be blank"
  end

  test "starts_at is required" do
    event = Event.new(title: "Concert", location: @location)
    assert_not event.valid?
    assert_includes event.errors[:starts_at], "can't be blank"
  end

  test "location is required" do
    event = Event.new(title: "Concert", starts_at: 2.days.from_now)
    assert_not event.valid?
    assert_includes event.errors[:location], "must exist"
  end

  test "duration must be a positive integer when set" do
    event = Event.new(title: "Concert", starts_at: 2.days.from_now, location: @location, duration: -5)
    assert_not event.valid?
    assert_includes event.errors[:duration], "must be greater than 0"
  end

  test "upcoming and past scopes split by starts_at" do
    future = Event.create!(title: "Future", starts_at: 3.days.from_now, location: @location)
    past = Event.create!(title: "Past", starts_at: 3.days.ago, location: @location)

    assert_includes Event.upcoming, future
    assert_not_includes Event.upcoming, past
    assert_includes Event.past, past
    assert_not_includes Event.past, future

    [ future, past ].each(&:destroy)
  end

  test "ends_at is starts_at plus duration" do
    starts = Time.current.change(usec: 0)
    event = Event.new(title: "Concert", starts_at: starts, duration: 90, location: @location)
    assert_equal starts + 90.minutes, event.ends_at
  end

  test "formatted_duration humanizes minutes" do
    assert_equal "2h", Event.new(duration: 120).formatted_duration
    assert_equal "1h 30min", Event.new(duration: 90).formatted_duration
    assert_equal "45min", Event.new(duration: 45).formatted_duration
    assert_nil Event.new(duration: nil).formatted_duration
  end

  test "location_uuid setter links location by uuid" do
    event = Event.new(title: "Concert", starts_at: 2.days.from_now)
    event.location_uuid = @location.uuid
    assert_equal @location, event.location
    assert_equal @location.uuid, event.location_uuid
  end

  test "city delegates to location" do
    event = Event.new(location: @location)
    assert_equal "Sarajevo", event.city
  end

  test "destroying location destroys its events" do
    loc = Location.create!(name: "Temp", city: "Mostar", lat: 43.34, lng: 17.81)
    Event.create!(title: "Temp Event", starts_at: 1.day.from_now, location: loc)
    assert_difference("Event.count", -1) { loc.destroy }
  end
end
