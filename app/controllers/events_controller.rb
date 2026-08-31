class EventsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_events

  def index
    @upcoming_events = in_chosen_city(listed_events.upcoming)
    @past_events = in_chosen_city(listed_events.past).limit(12)

    # City list for the simple filter (only cities that actually have events)
    @cities = listed_events.joins(:location).where.not(locations: { city: [ nil, "" ] })
                           .distinct.pluck("locations.city").compact.sort
  end

  def show
    @event = Event.includes(location: { photos_attachments: :blob }).find_by_public_id!(params[:id])
    # The panel renders title and date only, so the location is not loaded.
    @related_events = Event.where(location_id: @event.location_id)
                           .where.not(id: @event.id)
                           .upcoming
                           .limit(3)
  end

  private

  # An event is its own thing, connected to a place rather than owned by it, so
  # retiring the venue does not retire the event. The cards render the venue
  # photo, so the blobs load with the location.
  def listed_events
    Event.includes(location: { photos_attachments: :blob })
  end

  # Picking a city narrows the whole page. A Past heading listing Mostar under
  # a Tuzla filter would make the filter mean two things at once.
  def in_chosen_city(scope)
    return scope if params[:city].blank?

    scope.where(locations: { city: params[:city] })
  end

  def redirect_to_events
    redirect_to events_path, alert: I18n.t("events.not_found")
  end
end
