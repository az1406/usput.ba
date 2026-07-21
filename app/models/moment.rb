# frozen_string_literal: true

class Moment < ApplicationRecord
  include Identifiable
  include Browsable

  belongs_to :user
  belongs_to :plan
  belongs_to :location

  enum :visibility, { private_moment: 0, public_moment: 1 }, prefix: true
  enum :moderation_status, { pending: 0, approved: 1, rejected: 2 }

  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 200, 200 ]
    attachable.variant :square, resize_to_fill: [ 600, 600 ]
  end

  # Validations
  validates :note, length: { maximum: 1000 }
  validate :photo_present
  validate :acceptable_photo

  # A moment is never visible on publish alone — going public re-enters
  # moderation, so a curator must approve it before anyone else can see it.
  before_save :require_moderation_when_published

  # Scopes
  scope :chronological, -> { order(created_at: :asc) }
  scope :publicly_visible, -> { visibility_public_moment.approved }

  # Mirrors Location#display_photos: .variant on a non-image blob raises.
  def displayable?
    photo.attached? && photo.blob&.variable?
  end

  private

  def require_moderation_when_published
    self.moderation_status = :pending if visibility_public_moment? && visibility_changed?
  end

  def photo_present
    errors.add(:photo, :blank) unless photo.attached?
  end

  def acceptable_photo
    return unless photo.attached?

    if photo.blob.byte_size > 10.megabytes
      errors.add(:photo, "is too large (max 10MB)")
      return
    end

    acceptable_types = [ "image/jpeg", "image/png", "image/gif", "image/webp" ]
    unless acceptable_types.include?(photo.blob.content_type)
      errors.add(:photo, "must be JPEG, PNG, GIF, or WebP")
    end
  end
end
