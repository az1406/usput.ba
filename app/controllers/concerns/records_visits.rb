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
  # A reading carries its own error bar, and refusing every one wider than the
  # geofence refused every device without GPS. So the gate widens by the
  # reading's own accuracy, capped. The browser applies the identical rule
  # before submitting — when the two sides disagreed, the client offered a
  # check-in that the server then refused, which is two contradictory messages
  # on the one card close enough for the disagreement to show.
  MAX_ACCURACY_TOLERANCE_KM = 0.5

  private

  def visit_in_range?(location, lat, lng, accuracy_m = 0)
    helpers.geofence_disabled? || location.distance_from(lat, lng) <= visit_allowance_km(accuracy_m)
  end

  def visit_allowance_km(accuracy_m)
    tolerance = [ [ accuracy_m.to_f, 0 ].max / 1000, MAX_ACCURACY_TOLERANCE_KM ].min
    MAX_VISIT_DISTANCE_KM + tolerance
  end

  def visit_coordinates_required?
    !helpers.geofence_disabled?
  end

  # The row is the whole record of the act. The profile's counters used to be
  # written here too; they are projected from these rows now, so an import that
  # never came through this path reports the same numbers a check-in does.
  def record_visit_for(plan, location)
    current_user.plan_visits.find_or_create_by!(plan: plan, location: location)
  rescue ActiveRecord::RecordNotUnique
    # A double-tap raced us to the insert; the visit exists either way.
    nil
  end
end
