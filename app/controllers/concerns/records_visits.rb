# frozen_string_literal: true

# One rule for "I was here", whatever surface asks. The walk, the explore deck
# and the location page each used to carry their own distance check, which let
# the same act be accepted at 400 m on one screen and refused at 150 m on
# another. Surfaces still own their own response shape; the decision lives here.
module RecordsVisits
  extend ActiveSupport::Concern

  # Matches the warm/cold meter, which checks in at 100 m and has no band above
  # it — a looser gate here would make the meter lie.
  MAX_VISIT_DISTANCE_KM = 0.1

  private

  def visit_in_range?(location, lat, lng)
    helpers.geofence_disabled? || location.distance_from(lat, lng) <= MAX_VISIT_DISTANCE_KM
  end

  def visit_coordinates_required?
    !helpers.geofence_disabled?
  end

  def record_visit_for(plan, location)
    visit = current_user.plan_visits.find_or_create_by!(plan: plan, location: location)
    touch_visit_stats(location)
    visit
  rescue ActiveRecord::RecordNotUnique
    # A double-tap raced us to the insert; the visit exists either way.
    nil
  end

  # Lives here rather than on one surface: the profile's counters used to be
  # updated by the location page's check-in and by nothing else, so the same act
  # moved the badges on one screen and not on another.
  def touch_visit_stats(location)
    current_data = current_user.travel_profile_data
    stats = current_data["stats"] || {}
    stats["totalVisits"] = current_user.plan_visits.distinct.count(:location_id)

    if location.city.present? && !stats["citiesVisited"]&.include?(location.city)
      stats["citiesVisited"] = (stats["citiesVisited"] || []) + [ location.city ]
    end

    season = Location.current_season
    stats["seasonsVisited"] = (stats["seasonsVisited"] || []) + [ season ] unless stats["seasonsVisited"]&.include?(season)

    current_user.update!(
      # `visited` is projected from PlanVisit, never stored — see User#travel_profile_data.
      travel_profile_data: current_data.except("visited").merge(
        "stats" => stats,
        "updatedAt" => Time.current.iso8601
      )
    )
  end
end
