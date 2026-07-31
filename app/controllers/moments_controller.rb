# frozen_string_literal: true

class MomentsController < ApplicationController
  include ServesMomentPhotos

  before_action :require_login, except: :index
  before_action :set_plan

  def index
    @location = Location.find_by_public_id!(params[:location_id])
    # Reached without a plan (a place browsed outside one): a signed-in traveller
    # still needs somewhere to upload to, and that is their explore plan. A guest
    # gets no plan and the form renders as a sign-in link.
    @plan ||= Plan.explore_bosnia_for(current_user) if logged_in?
    @moments = if logged_in?
      current_user.moments.where(location: @location).with_attached_photo.includes(:plan).chronological
    else
      Moment.none
    end
    @public_moments = Moment.publicly_visible.where(location: @location)
                            .with_attached_photo.chronological

    render layout: false
  end

  def create
    @moment = current_user.moments.build(moment_params)
    @moment.plan = @plan
    @moment.location = Location.find_by_public_id!(params[:moment][:location_id])

    respond_to do |format|
      if @moment.save
        format.html { redirect_back fallback_location: plan_path(@plan), notice: t("flash.moment.created") }
        format.turbo_stream { render :update, locals: { location: @moment.location } }
      else
        format.html { redirect_back fallback_location: plan_path(@plan), alert: @moment.errors.full_messages.join(", ") }
        format.turbo_stream do
          render :update, locals: { location: @moment.location, alert: @moment.errors.full_messages.join(", ") }
        end
      end
    end
  end

  def photo
    moment = current_user.moments.find_by_public_id!(params[:id])
    stream_moment_photo(moment, public: false)
  end

  def publish
    moment = current_user.moments.find_by_public_id!(params[:id])
    moment.update!(visibility: :public_moment)
    respond_to do |format|
      format.turbo_stream { render :update, locals: { location: moment.location } } if params[:context].present?
      format.html { redirect_back fallback_location: plan_path(@plan), notice: t("flash.moment.published") }
    end
  end

  def unpublish
    current_user.moments.find_by_public_id!(params[:id]).update!(visibility: :private_moment)
    redirect_back fallback_location: plan_path(@plan), notice: t("flash.moment.unpublished")
  end

  def destroy
    moment = current_user.moments.find_by_public_id!(params[:id])
    location = moment.location
    card = helpers.dom_id(moment)
    moment.destroy

    respond_to do |format|
      format.html { redirect_back fallback_location: plan_path(@plan), notice: t("flash.moment.destroyed") }
      format.turbo_stream do
        if params[:context] == "browse"
          render turbo_stream: turbo_stream.remove(card)
        else
          render :update, locals: { location: location }
        end
      end
    end
  end

  private

  # The location-nested index carries no plan_id: reading a place's moments is
  # not plan-scoped, and a guest in explore mode has no plan to name. Every
  # writing action is routed under a plan, and still demands one here.
  def set_plan
    return if params[:plan_id].blank? && action_name == "index"

    @plan = Plan.find_by_public_id!(params[:plan_id])

    unless @plan.visibility_public_plan? || @plan.user_id == current_user&.id
      raise ActiveRecord::RecordNotFound
    end
  end

  def moment_params
    params.require(:moment).permit(:photo, :note, :taken_at)
  end
end
