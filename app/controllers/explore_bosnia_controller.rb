class ExploreBosniaController < ApplicationController
  before_action :require_login, only: :experience

  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_menu

  GRID_SIZE = 4
  DECK_SIZE = 10

  # Hand-picked distinct moods — the dense types overlap heavily on the same
  # locations (culture and history are near-identical sets), so density alone
  # would fill the grid with duplicates.
  CURATED_KEYS = %w[history food nature sport].freeze

  def show
    counts = LocationExperienceType.joins(:location)
                                   .merge(Location.with_coordinates)
                                   .group(:experience_type_id)
                                   .count
    types_by_key = ExperienceType.active.index_by(&:key)
    curated = CURATED_KEYS.filter_map { |key| types_by_key[key] }
                          .select { |type| counts[type.id].to_i.positive? }
    fallback = ExperienceType.active.ordered
                             .select { |type| counts[type.id].to_i.positive? }
                             .sort_by { |type| -counts[type.id] } - curated
    @experience_types = (curated + fallback).first(GRID_SIZE)
  end

  def experience
    @experience_type = ExperienceType.active.find_by!(key: params[:experience_key])
    @plan = Plan.explore_bosnia_for(current_user)
    @lat = params[:lat].presence&.to_f
    @lng = params[:lng].presence&.to_f
    @locations = dealt_locations
    @reviews_by_location_id = Review.where(reviewable_type: "Location", reviewable_id: @locations.map(&:id))
                                    .recent
                                    .group_by(&:reviewable_id)
    @public_moments_by_location_id = Moment.publicly_visible
                                           .where(location_id: @locations.map(&:id))
                                           .with_attached_photo
                                           .chronological
                                           .group_by(&:location_id)
    @moments_by_location_id = current_user.moments
                                          .where(location_id: @locations.map(&:id))
                                          .with_attached_photo
                                          .includes(:plan)
                                          .chronological
                                          .group_by(&:location_id)
    # Visited anywhere counts — the card stays in the deck, stamped (operator's
    # call: swiping a visited card just reports "already visited").
    @visited_location_ids = current_user.plan_visits
                                        .where(location_id: @locations.map(&:id))
                                        .pluck(:location_id)
                                        .to_set
  end

  private

  def dealt_locations
    # The join table is the source of truth (the jsonb column is a synced
    # cache) — the grid's counts and the deck must agree.
    scope = Location.with_coordinates
                    .joins(:location_experience_types)
                    .where(location_experience_types: { experience_type_id: @experience_type.id })
                    .includes(photos_attachments: :blob)
    return scope.limit(DECK_SIZE).to_a unless @lat && @lng

    # SQL-side distance ordering + limit — the corpus may be huge; never load it
    # all. The radius is the whole globe: distance only orders, it never filters
    # (a traveller planning from abroad must still see the closest places).
    scope.near([ @lat, @lng ], 40_075, units: :km).limit(DECK_SIZE).to_a
  end

  def redirect_to_menu
    redirect_to explore_bosnia_path
  end
end
