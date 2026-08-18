# frozen_string_literal: true

class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true, counter_cache: :likes_count

  validates :user_id, uniqueness: { scope: [ :likeable_type, :likeable_id ] }
end
