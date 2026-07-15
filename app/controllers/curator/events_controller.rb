# frozen_string_literal: true

module Curator
  class EventsController < BaseController
    before_action :set_event, only: [ :show, :edit, :update, :destroy ]
    before_action :load_form_options, only: [ :new, :create, :edit, :update ]

    def index
      @events = Event.includes(:location).order(starts_at: :desc)
      @events = @events.joins(:location).where(locations: { city: params[:city_name] }) if params[:city_name].present?
      @events = @events.where("events.title ILIKE ?", "%#{params[:search]}%") if params[:search].present?

      page = params[:items_page] || params[:page] || 1
      @events = @events.page(page).per(6)

      if params[:partial] == "items" && request.xhr?
        return render partial: "curator/events/event_items", locals: { events: @events }, layout: false
      end

      @city_names = Location.joins(:events).where.not(city: [ nil, "" ]).distinct.pluck(:city).sort

      @pending_proposals = current_user.content_changes
        .where(changeable_type: "Event")
        .or(current_user.content_changes.where(changeable_class: "Event"))
        .pending
        .order(created_at: :desc)
    end

    def show
      @pending_proposal = pending_proposal_for(@event)
    end

    def new
      @event = Event.new
    end

    def create
      proposal = current_user.content_changes.build(
        change_type: :create_content,
        changeable_class: "Event",
        proposed_data: proposal_data_from_params
      )

      if proposal.save
        record_activity("proposal_created", recordable: proposal, metadata: { type: "Event", title: proposal_data_from_params["title"] })
        redirect_to curator_events_path, notice: t("curator.proposals.submitted_for_review"), status: :see_other
      else
        @event = Event.new(event_params)
        flash.now[:alert] = t("curator.proposals.failed_to_submit")
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @pending_proposal = pending_proposal_for(@event)
    end

    def update
      proposal = ContentChange.find_or_create_for_update(
        changeable: @event,
        user: current_user,
        original_data: build_original_data,
        proposed_data: proposal_data_from_params
      )

      if proposal.persisted?
        action = proposal.contributions.exists?(user: current_user) ? "proposal_contributed" : "proposal_updated"
        record_activity(action, recordable: @event, metadata: { type: "Event", title: @event.title })
        redirect_to curator_event_path(@event), notice: t("curator.proposals.submitted_for_review"), status: :see_other
      else
        flash.now[:alert] = t("curator.proposals.failed_to_submit")
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      proposal = ContentChange.find_or_create_for_delete(
        changeable: @event,
        user: current_user,
        original_data: build_original_data
      )

      if proposal.persisted?
        record_activity("proposal_deleted", recordable: @event, metadata: { type: "Event", title: @event.title })
        redirect_to curator_events_path, notice: t("curator.proposals.delete_submitted_for_review"), status: :see_other
      else
        redirect_to curator_events_path, alert: t("curator.proposals.failed_to_submit"), status: :see_other
      end
    end

    private

    def set_event
      @event = Event.find_by_public_id!(params[:id])
    end

    def editable_attributes
      %w[title description info starts_at duration]
    end

    def build_original_data
      data = @event.attributes.slice(*editable_attributes)
      data["location_uuid"] = @event.location_uuid
      data
    end

    def proposal_data_from_params
      data = event_params.to_h

      if params[:event][:location_uuid].present?
        data["location_uuid"] = params[:event][:location_uuid]
      end

      data
    end

    def event_params
      params.require(:event).permit(
        :title, :description, :info, :starts_at, :duration, :location_uuid
      )
    end

    def load_form_options
      @locations = Location.order(:name)
    end
  end
end
