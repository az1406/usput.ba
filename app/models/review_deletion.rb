# frozen_string_literal: true

class ReviewDeletion < ApplicationRecord
  belongs_to :reviewable, polymorphic: true, optional: true
  belongs_to :user, optional: true
  belongs_to :deleted_by, class_name: "User", optional: true

  enum :source, { manual: 0, agent: 1, curator: 2 }

  validates :review_uuid, :rating, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_rating, ->(rating) { where(rating: rating) }
end
