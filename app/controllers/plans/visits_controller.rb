# frozen_string_literal: true

class Plans::VisitsController < ApplicationController
  before_action :require_login
  before_action :set_plan

  def create
    location = Location.find_by_public_id!(params[:location_id])
    mark_visited(location)

    render_location(location)
  end

  def destroy
    location = Location.find_by_public_id!(params[:id])
    current_user.plan_visits.where(plan: @plan, location: location).destroy_all

    render_location(location)
  end

  private

  def mark_visited(location)
    current_user.plan_visits.find_or_create_by!(plan: @plan, location: location)
  rescue ActiveRecord::RecordNotUnique
    # A double-tap raced us to the insert; the visit exists either way.
    nil
  end

  def render_location(location)
    respond_to do |format|
      format.html { redirect_back fallback_location: start_plan_path(@plan) }
      format.turbo_stream { render template: "moments/update", locals: { location: location } }
    end
  end

  def set_plan
    @plan = Plan.find_by_public_id!(params[:plan_id])

    unless @plan.visibility_public_plan? || @plan.user_id == current_user.id
      raise ActiveRecord::RecordNotFound
    end
  end
end
