# frozen_string_literal: true

class MomentsController < ApplicationController
  # Looked up here rather than passed through, so a caller cannot make the
  # server process arbitrary variants on demand.
  PHOTO_VARIANTS = {
    "thumb" => { resize_to_fill: [ 200, 200 ] },
    "square" => { resize_to_fill: [ 600, 600 ] }
  }.freeze

  DEFAULT_PHOTO_VARIANT = "square"

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

  # Streamed, not served as an Active Storage URL: a signed blob url is a bearer
  # token — Rails serves it without looking at the session.
  def photo
    moment = current_user.moments.find_by_public_id!(params[:id])
    return head :not_found unless moment.displayable?

    variant = moment.photo.variant(PHOTO_VARIANTS.fetch(params[:size], PHOTO_VARIANTS[DEFAULT_PHOTO_VARIANT])).processed

    # The browser may cache it; shared caches must not.
    expires_in 1.hour, public: false
    send_data variant.download,
              type: moment.photo.blob.content_type,
              disposition: "inline"
  rescue Vips::Error, MiniMagick::Error => e
    # content_type is the uploader's word, so non-image bytes reach the processor.
    Rails.logger.warn "[Moments] Unprocessable photo for moment #{params[:id]}: #{e.message}"
    head :unprocessable_entity
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
