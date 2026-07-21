# frozen_string_literal: true

class Plans::VisitsController < ApplicationController
  before_action :require_login
  before_action :set_plan

  MAX_VISIT_DISTANCE_KM = 0.1 # 100 meters

  def create
    location = Location.find_by_public_id!(params[:location_id])

    if (reason = out_of_range_reason(location))
      return render_location(location, alert: reason)
    end

    mark_visited(location)
    render_location(location)
  end

  def destroy
    location = Location.find_by_public_id!(params[:id])
    current_user.plan_visits.where(plan: @plan, location: location).destroy_all

    render_location(location)
  end

  private

  def out_of_range_reason(location)
    return nil unless location.geocoded?

    lat = params[:user_lat].to_f
    lng = params[:user_lng].to_f
    return t("plans.start.need_location") if lat.zero? && lng.zero?

    distance_km = location.distance_from(lat, lng)
    return nil if distance_km <= MAX_VISIT_DISTANCE_KM

    t("plans.start.too_far", distance: format_distance(distance_km), max: (MAX_VISIT_DISTANCE_KM * 1000).to_i)
  end

  def format_distance(km)
    km >= 1 ? "#{km.round(1)} km" : "#{(km * 1000).round} m"
  end

  def mark_visited(location)
    current_user.plan_visits.find_or_create_by!(plan: @plan, location: location)
  rescue ActiveRecord::RecordNotUnique
    # A double-tap raced us to the insert; the visit exists either way.
    nil
  end

  def render_location(location, alert: nil)
    respond_to do |format|
      format.html { redirect_back fallback_location: start_plan_path(@plan), alert: alert }
      format.turbo_stream { render template: "moments/update", locals: { location: location, alert: alert } }
    end
  end

  def set_plan
    @plan = Plan.find_by_public_id!(params[:plan_id])

    unless @plan.visibility_public_plan? || @plan.user_id == current_user.id
      raise ActiveRecord::RecordNotFound
    end
  end
end
