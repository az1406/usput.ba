module Curator
  class ReviewsController < BaseController
    before_action :set_review, only: [ :show, :destroy, :approve, :reject ]
    rescue_from ActiveRecord::RecordNotFound, with: :review_not_found

    def index
      @reviews = if params[:deleted].present?
        ReviewDeletion.includes(:reviewable, :user, :deleted_by).recent
      else
        scope = Review.includes(:reviewable, :user).order(created_at: :desc)
        params[:status].present? ? scope.where(moderation_status: params[:status]) : scope
      end
      @reviews = @reviews.by_rating(params[:rating]) if params[:rating].present?
      @reviews = @reviews.where(reviewable_type: params[:type]) if params[:type].present?

      if params[:search].present?
        @reviews = @reviews.where("comment ILIKE ? OR author_name ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
      end

      @reviews = @reviews.page(params[:page]).per(20)

      @stats = {
        total: Review.count,
        pending: Review.pending.count,
        approved: Review.approved.count,
        rejected: Review.rejected.count,
        average_rating: Review.approved.average(:rating)&.round(2) || 0,
        with_comments: Review.with_comments.count,
        by_type: Review.group(:reviewable_type).count,
        by_rating: Review.group(:rating).count
      }

      # Show pending proposals for this curator
      @pending_proposals = current_user.content_changes
        .where(changeable_type: "Review")
        .pending
        .order(created_at: :desc)
    end

    def show
    end

    def approve
      @review.update!(moderation_status: :approved)
      record_activity(:approve_review, recordable: @review)
      redirect_to curator_reviews_path, notice: t("curator.reviews.flash.approved"), status: :see_other
    end

    # Rejecting hides a comment rather than destroying it: the deletion trail is
    # for what is gone, and a curator can still change their mind here.
    def reject
      @review.update!(moderation_status: :rejected)
      record_activity(:reject_review, recordable: @review)
      redirect_to curator_reviews_path, notice: t("curator.reviews.flash.rejected"), status: :see_other
    end

    def destroy
      # Use find_or_create to ensure only one pending proposal per resource
      proposal = ContentChange.find_or_create_for_delete(
        changeable: @review,
        user: current_user,
        original_data: @review.attributes.slice(*editable_attributes)
      )

      if proposal.persisted?
        redirect_to curator_reviews_path, notice: t("curator.proposals.delete_submitted_for_review"), status: :see_other
      else
        redirect_to curator_reviews_path, alert: t("curator.proposals.failed_to_submit"), status: :see_other
      end
    end

    private

    def set_review
      # Review includes Identifiable, so to_param — and therefore every generated
      # path — is the uuid. Review.find looks up by id and never resolves it.
      @review = Review.find_by_public_id!(params[:id])
    end

    def review_not_found
      redirect_to curator_reviews_path, alert: "Review not found. It may have been deleted."
    end

    def editable_attributes
      %w[rating comment author_name reviewable_type reviewable_id user_id]
    end
  end
end
