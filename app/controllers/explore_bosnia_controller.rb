class ExploreBosniaController < ApplicationController
  before_action :require_login, only: :experience

  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_menu

  PAGE_SIZE = 10

  # Day-trip range, and the bound Geocoder turns into its WHERE box — without
  # one the lat/lng index is useless and every request sorts the whole table.
  RADIUS_KM = 50

  # An admin is demoing the walk, not taking it: deal the whole country so the
  # reel is never empty, and eat the full sort — it is one signed-in reviewer.
  ADMIN_RADIUS_KM = 20_000

  # Where to deal from for an admin who never answered the location prompt.
  DEFAULT_ORIGIN = [ 43.8563, 18.4131 ].freeze # Sarajevo

  BROWSE_TILES = {
    "history" => %w[history],
    "culture" => %w[culture art],
    "sport_nature" => %w[sport nature woods mountains],
    "food_drinks" => %w[food vegan vegetarian meat],
    "religious" => %w[religious],
    "relax" => %w[wellness nightlife]
  }.freeze

  def show
    @tile_keys = BROWSE_TILES.keys
  end

  def experience
    @tile_key = params[:experience_key]
    @type_keys = BROWSE_TILES[@tile_key] or raise ActiveRecord::RecordNotFound

    @lat, @lng = origin
    @needs_location = @lat.nil?
    return if @needs_location

    @plan = Plan.explore_bosnia_for(current_user)
    @page = [ params[:page].to_i, 1 ].max
    @locations = dealt_locations
    @has_more = @locations.size == PAGE_SIZE
    # "nothing here" and "you have been to all of it" read identically to a
    # traveller otherwise, and the second is the common one.
    @all_visited = @locations.empty? && @page == 1 && dealt_locations(skip_visited: false).any?
  end

  private

  def origin
    lat = params[:lat].presence&.to_f
    lng = params[:lng].presence&.to_f
    return [ lat, lng ] if lat && lng
    # A denied location prompt is a dead end for a traveller, but an admin is
    # here to review the walk — deal from the default rather than stopping them.
    current_user_admin? ? DEFAULT_ORIGIN : [ nil, nil ]
  end

  def radius_km
    current_user_admin? ? ADMIN_RADIUS_KM : RADIUS_KM
  end

  def dealt_locations(skip_visited: true)
    scope = Location.with_coordinates.where(id: tile_location_ids)
    scope = scope.where.not(id: current_user.plan_visits.select(:location_id)) if skip_visited

    scope.includes(photos_attachments: :blob)
         .near([ @lat, @lng ], radius_km, units: :km)
         .offset((@page - 1) * PAGE_SIZE)
         .limit(PAGE_SIZE)
         .to_a
  end

  # Ids, not a join: a tile spans several types, and SELECT DISTINCT can't be
  # combined with the computed distance Geocoder orders by.
  def tile_location_ids
    type_ids = ExperienceType.active.where(key: @type_keys).select(:id)

    Location.joins(:location_experience_types)
            .where(location_experience_types: { experience_type_id: type_ids })
            .distinct
            .select(:id)
  end

  def redirect_to_menu
    redirect_to explore_bosnia_path
  end
end
