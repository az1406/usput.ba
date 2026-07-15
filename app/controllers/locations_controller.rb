class LocationsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_explore

  def show
    @location = Location.includes(:reviews).find_by_public_id!(params[:id])
    @reviews = @location.reviews.recent.limit(10)
    @review = Review.new
    @nearby_locations = @location.nearby_featured(limit: 3)

    # Experiences that include this location
    experiences_scope = @location.experiences
                                 .includes(:experience_category)
                                 .with_attached_cover_photo
                                 .order(average_rating: :desc)
    @related_experiences = experiences_scope.limit(3)
    @total_experiences_count = @location.experiences.count

    # Public plans that include this location (through experiences)
    plans_scope = Plan.public_plans
                      .joins(experiences: :locations)
                      .where(locations: { id: @location.id })
                      .distinct
    @related_plans = plans_scope.order(average_rating: :desc).limit(3)
    @total_plans_count = plans_scope.count

    # Upcoming events at this location, or elsewhere in the same city.
    # Events tied to THIS exact location are shown first.
    @upcoming_events =
      if @location.city.present?
        Event.upcoming
             .includes(:location)
             .where(location: Location.where(city: @location.city))
             .reorder(Arel.sql("CASE WHEN events.location_id = #{@location.id.to_i} THEN 0 ELSE 1 END ASC"), starts_at: :asc)
             .limit(4)
      else
        @location.events.upcoming.includes(:location).limit(4)
      end
  end

  def audio_tour
    @location = Location.find_by_public_id!(params[:id])
  end

  private

  def redirect_to_explore
    redirect_to explore_path, alert: I18n.t("locations.not_found", default: "Location not found. Explore other destinations.")
  end
end
