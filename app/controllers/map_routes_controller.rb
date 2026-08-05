class MapRoutesController < ApplicationController
  CACHE_TTL = 1.hour

  def show
    coordinates = coordinate_params
    return head :bad_request unless coordinates
    return head :service_unavailable if ENV["OPENROUTESERVICE_API_KEY"].blank?

    profile = requested_profile
    # A nil is a timeout, not an answer; caching it pins a 502 for an hour.
    route = Rails.cache.fetch(cache_key(coordinates, profile), expires_in: CACHE_TTL, skip_nil: true) do
      Maps::RouteFetcher.call(**coordinates, profile: profile)
    end
    return head :bad_gateway unless route

    render json: route
  end

  private

  def coordinate_params
    values = params.values_at(:from_lat, :from_lng, :to_lat, :to_lng)
    return nil if values.any?(&:blank?)

    from_lat, from_lng, to_lat, to_lng = values.map { |value| Float(value) }
    return nil unless from_lat.abs <= 90 && to_lat.abs <= 90 && from_lng.abs <= 180 && to_lng.abs <= 180

    { from_lat: from_lat, from_lng: from_lng, to_lat: to_lat, to_lng: to_lng }
  rescue ArgumentError, TypeError
    nil
  end

  def requested_profile
    Maps::RouteFetcher::PROFILES.include?(params[:profile]) ? params[:profile] : Maps::RouteFetcher::WALKING
  end

  # Rounded so nearby requests share a cache entry (~11 m at 4 decimals).
  def cache_key(coordinates, profile)
    rounded = coordinates.values.map { |value| value.round(4) }.join(",")
    "map_route/#{profile}/#{rounded}"
  end
end
