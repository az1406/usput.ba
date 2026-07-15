# frozen_string_literal: true

# Event represents a time-bound happening (festival, concert, exhibition, ...)
# tied to a single Location. Events are proposed by curators and become visible
# to everyone only after an admin approves the ContentChange proposal.
#
# Note: Events are intentionally NOT part of the Browse/search index.
class Event < ApplicationRecord
  include Identifiable

  # Associations
  belongs_to :location

  # Validations
  validates :title, presence: true
  validates :starts_at, presence: true
  validates :duration, numericality: { greater_than: 0, only_integer: true }, allow_nil: true

  # Scopes
  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(starts_at: :asc) }
  scope :past, -> { where("starts_at < ?", Time.current).order(starts_at: :desc) }
  scope :chronological, -> { order(starts_at: :asc) }

  # When the event ends (based on duration in minutes)
  def ends_at
    return nil unless starts_at
    return starts_at unless duration

    starts_at + duration.minutes
  end

  # Whether the event is in the future
  def upcoming?
    starts_at.present? && starts_at >= Time.current
  end

  # Human-readable duration, mirrors Experience#formatted_duration
  def formatted_duration
    return nil unless duration

    hours = duration / 60
    minutes = duration % 60

    if hours > 0 && minutes > 0
      "#{hours}h #{minutes}min"
    elsif hours > 0
      "#{hours}h"
    else
      "#{minutes}min"
    end
  end

  # City is derived from the connected location (for display/filtering)
  def city
    location&.city
  end

  # Setter used by content change proposals to link a location by its UUID
  def location_uuid=(uuid)
    return if uuid.blank?

    self.location = Location.find_by(uuid: uuid)
  end

  # Getter for the connected location UUID
  def location_uuid
    location&.uuid
  end
end
