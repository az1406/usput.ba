# frozen_string_literal: true

class MomentsController < ApplicationController
  include ServesMomentPhotos

  before_action :require_login
  before_action :set_plan

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
    current_user.moments.find_by_public_id!(params[:id]).update!(visibility: :public_moment)
    redirect_back fallback_location: plan_path(@plan), notice: t("flash.moment.published")
  end

  def unpublish
    current_user.moments.find_by_public_id!(params[:id]).update!(visibility: :private_moment)
    redirect_back fallback_location: plan_path(@plan), notice: t("flash.moment.unpublished")
  end

  def destroy
    moment = current_user.moments.find_by_public_id!(params[:id])
    location = moment.location
    moment.destroy

    respond_to do |format|
      format.html { redirect_back fallback_location: plan_path(@plan), notice: t("flash.moment.destroyed") }
      format.turbo_stream { render :update, locals: { location: location } }
    end
  end

  private

  def set_plan
    @plan = Plan.find_by_public_id!(params[:plan_id])

    unless @plan.visibility_public_plan? || @plan.user_id == current_user.id
      raise ActiveRecord::RecordNotFound
    end
  end

  def moment_params
    params.require(:moment).permit(:photo, :note, :taken_at)
  end
end
