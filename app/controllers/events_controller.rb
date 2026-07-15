class EventsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_events

  def index
    @upcoming_events = Event.includes(:location).upcoming
    @upcoming_events = @upcoming_events.where(locations: { city: params[:city] }) if params[:city].present?

    @past_events = Event.includes(:location).past.limit(12)

    # City list for the simple filter (only cities that actually have events)
    @cities = Event.joins(:location).where.not(locations: { city: [ nil, "" ] })
                   .distinct.pluck("locations.city").compact.sort
  end

  def show
    @event = Event.includes(:location).find_by_public_id!(params[:id])
    @related_events = Event.includes(:location)
                           .where(location_id: @event.location_id)
                           .where.not(id: @event.id)
                           .upcoming
                           .limit(3)
  end

  private

  def redirect_to_events
    redirect_to events_path, alert: I18n.t("events.not_found", default: "Event not found. Explore other events.")
  end
end
