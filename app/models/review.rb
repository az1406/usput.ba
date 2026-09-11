class Review < ApplicationRecord
  include Identifiable

  # reviews_count is maintained by update_reviewable_counters rather than by a
  # counter_cache: a cache counts pending reviews too, which would move a
  # place's score before anyone is allowed to read the comment that moved it.
  belongs_to :reviewable, polymorphic: true
  belongs_to :user, optional: true

  attr_accessor :deleted_by, :deletion_reason, :moderation_verdict

  enum :moderation_status, { pending: 0, approved: 1, rejected: 2 }

  validates :rating, presence: true,
                     numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :comment, length: { maximum: 1000 }
  validates :author_name, length: { maximum: 100 }

  before_validation :skip_moderation_without_comment, on: :create

  after_save :update_reviewable_counters
  after_destroy :update_reviewable_counters
  after_create_commit :moderate_comment, if: -> { comment.present? }
  before_destroy :record_deletion, unless: :destroyed_by_association

  scope :recent, -> { order(created_at: :desc) }
  scope :by_rating, ->(rating) { where(rating: rating) }
  scope :with_comments, -> { where.not(comment: [ nil, "" ]) }
  scope :publicly_visible, -> { approved }

  # The agent found something and a curator has not ruled yet — what the
  # warning triangle on the curator's list is drawn from.
  def flagged?
    pending? && moderation_category.present? && moderation_category != Ai::ReviewModerator::CLEAN
  end

  # Spelled out in full because Tailwind only generates class names it can read
  # in the source — a built-up string would leave the badge with no background
  # and no error. Mirrors Moment#status_classes.
  def moderation_classes
    case moderation_status
    when "approved" then "bg-emerald-100 dark:bg-emerald-900/40 text-emerald-800 dark:text-emerald-300"
    when "rejected" then "bg-red-100 dark:bg-red-900/40 text-red-800 dark:text-red-300"
    else "bg-amber-100 dark:bg-amber-900/40 text-amber-800 dark:text-amber-300"
    end
  end

  # The curator's list must say why a comment is not public, whichever way it got
  # there: the agent ruled against it, the agent was not sure, or no verdict ever
  # arrived. Silence on a parked comment reads as the queue being broken.
  def moderation_note_key
    return if approved?
    return "unchecked" if moderation_category.blank?
    return "hidden_as" if rejected?
    return "flagged_as" if flagged?

    "unsure"
  end

  private

  # A rating with no comment has nothing for the agent to read, so holding it
  # back would hide a score behind a queue that is never worked.
  def skip_moderation_without_comment
    self.moderation_status = :approved if comment.blank?
  end

  # Moderation never blocks a comment: with the inline adapter the model call
  # runs inside the request, and a failed call must not turn a saved review
  # into an error page.
  def moderate_comment
    Ai::ReviewModerator.enqueue(self)
  rescue StandardError => e
    Rails.logger.error "Failed to moderate review #{id}: #{e.message}"
  end

  # Every deletion leaves a row, whichever hand did it, so the curator list can
  # show what was removed. A review going down with its place is not one.
  def record_deletion
    ReviewDeletion.create!(
      review_uuid: uuid,
      reviewable_type: reviewable_type,
      reviewable_id: reviewable_id,
      user: user,
      rating: rating,
      comment: comment,
      author_name: author_name,
      deleted_by: deleted_by,
      reason: deletion_reason,
      source: deletion_source,
      **(moderation_verdict || {}).slice(:category, :confidence, :model)
    )
  end

  def deletion_source
    return :agent if moderation_verdict
    return :curator if deleted_by

    :manual
  end

  # Only approved reviews carry a score. A pending comment that still counted
  # would let anyone move a place's rating without a curator ever reading it.
  def update_reviewable_counters
    return unless reviewable

    approved = reviewable.reviews.approved
    reviewable.update_columns(
      average_rating: (approved.average(:rating) || 0).round(2),
      reviews_count: approved.count
    )
  end
end
