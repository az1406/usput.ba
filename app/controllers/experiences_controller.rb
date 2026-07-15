class ExperiencesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_explore

  def show
    @experience = Experience.includes(:locations, :reviews).find_by_public_id!(params[:id])
    @reviews = @experience.reviews.recent.limit(10)
    @review = Review.new
    @nearby_experiences = @experience.nearby_featured(limit: 3)

    # Public plans that include this experience
    plans_scope = Plan.public_plans
                      .joins(:experiences)
                      .where(experiences: { id: @experience.id })
                      .distinct
    @related_plans = plans_scope.order(average_rating: :desc).limit(3)
    @total_plans_count = plans_scope.count

    @bike_rentals = load_bike_rentals(@experience)
  end

  private

  # For cycling experiences, look up nearby bicycle rentals via Geoapify.
  # Cached per rounded coordinate so we hit the API at most a handful of times
  # per area, and fail silently so the page always renders.
  def load_bike_rentals(experience)
    return [] unless experience.cycling?

    coords = experience.primary_coordinates
    return [] unless coords

    lat, lng = coords
    cache_key = "bike_rentals/#{lat.round(3)}/#{lng.round(3)}"

    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      GeoapifyService.new.bicycle_rentals_near(lat: lat, lng: lng, max_results: 5)
    end
  rescue GeoapifyService::ConfigurationError => e
    Rails.logger.warn "[Experiences] Geoapify not configured: #{e.message}"
    []
  end

  def redirect_to_explore
    redirect_to explore_path, alert: I18n.t("experiences.not_found", default: "Experience not found. Explore other experiences.")
  end
end
