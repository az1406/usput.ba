# frozen_string_literal: true

require "test_helper"

class Curator::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @curator = User.create!(username: "ev_curator_#{SecureRandom.hex(4)}", password: "password123", user_type: :curator)
    @admin = User.create!(username: "ev_admin_#{SecureRandom.hex(4)}", password: "password123", user_type: :admin)
    @location = Location.create!(name: "Event Loc", city: "Sarajevo", lat: 43.8563, lng: 18.4131)
    @event = Event.create!(title: "Existing Event", starts_at: 3.days.from_now, duration: 90, location: @location)
  end

  teardown do
    ContentChange.destroy_all
    CuratorActivity.destroy_all
    Event.destroy_all
    @location&.destroy
    User.where(id: [ @curator.id, @admin.id ]).destroy_all
  end

  test "index requires login" do
    get curator_events_path
    assert_redirected_to login_path
  end

  test "curator can view index" do
    login_as(@curator)
    get curator_events_path
    assert_response :success
  end

  test "curator can view new form" do
    login_as(@curator)
    get new_curator_event_path
    assert_response :success
  end

  test "curator can view event" do
    login_as(@curator)
    get curator_event_path(@event)
    assert_response :success
  end

  test "create submits a proposal instead of creating directly" do
    login_as(@curator)
    assert_no_difference("Event.count") do
      assert_difference("ContentChange.count", 1) do
        post curator_events_path, params: { event: {
          title: "Proposed Event",
          description: "A proposed event",
          info: "Some info",
          starts_at: 4.days.from_now.strftime("%Y-%m-%dT%H:%M"),
          duration: 120,
          location_uuid: @location.uuid
        } }
      end
    end
    assert_redirected_to curator_events_path
  end

  test "approved create proposal builds the event with its location" do
    login_as(@curator)
    post curator_events_path, params: { event: {
      title: "Approved Event",
      starts_at: 4.days.from_now.strftime("%Y-%m-%dT%H:%M"),
      duration: 60,
      location_uuid: @location.uuid
    } }
    proposal = ContentChange.last

    assert_difference("Event.count", 1) do
      assert proposal.approve!(@admin), "approval should succeed"
    end
    created = Event.find_by(title: "Approved Event")
    assert_equal @location, created.location
  end

  test "update submits a proposal instead of changing the event" do
    login_as(@curator)
    assert_difference("ContentChange.count", 1) do
      patch curator_event_path(@event), params: { event: { title: "Renamed Event", duration: 45 } }
    end
    assert_redirected_to curator_event_path(@event)
    assert_equal "Existing Event", @event.reload.title

    proposal = ContentChange.last
    assert_equal "update_content", proposal.change_type
    assert_equal @event, proposal.changeable
    assert_equal "Renamed Event", proposal.proposed_data["title"]
    assert_equal @location.uuid, proposal.original_data["location_uuid"]
  end

  test "approved update proposal changes the event" do
    login_as(@curator)
    patch curator_event_path(@event), params: { event: { title: "Renamed Event", duration: 45 } }

    assert ContentChange.last.approve!(@admin), "approval should succeed"
    @event.reload
    assert_equal "Renamed Event", @event.title
    assert_equal 45, @event.duration
    assert_equal @location, @event.location
  end

  test "destroy submits a delete proposal instead of deleting" do
    login_as(@curator)
    assert_difference("ContentChange.count", 1) do
      assert_no_difference("Event.count") { delete curator_event_path(@event) }
    end
    assert_redirected_to curator_events_path

    proposal = ContentChange.last
    assert_equal "delete_content", proposal.change_type
    assert_equal @event, proposal.changeable
    assert_equal @curator, proposal.user
  end

  test "approved delete proposal removes the event" do
    login_as(@curator)
    delete curator_event_path(@event)
    assert_difference("Event.count", -1) { assert ContentChange.last.approve!(@admin) }
  end

  test "show prints the start in the curator's locale" do
    login_as(@curator)
    get curator_event_path(@event), params: { locale: :bs }
    assert_match I18n.l(@event.starts_at, format: :long, locale: :bs), response.body
  end

  private

  def login_as(user)
    post login_path, params: { username: user.username, password: "password123" }
  end
end
