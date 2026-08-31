# frozen_string_literal: true

class Event < ApplicationRecord
  include Identifiable

  belongs_to :location

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :duration, numericality: { greater_than: 0, only_integer: true }, allow_nil: true

  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(starts_at: :asc) }
  scope :past, -> { where("starts_at < ?", Time.current).order(starts_at: :desc) }
  scope :chronological, -> { order(starts_at: :asc) }

  def ends_at
    return nil unless starts_at
    return starts_at unless duration

    starts_at + duration.minutes
  end

  def upcoming?
    starts_at.present? && starts_at >= Time.current
  end

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

  def city
    location&.city
  end

  # Proposals carry the location's UUID, not its id.
  def location_uuid=(uuid)
    return if uuid.blank?

    self.location = Location.find_by(uuid: uuid)
  end

  def location_uuid
    location&.uuid
  end
end
