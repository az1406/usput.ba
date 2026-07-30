# frozen_string_literal: true

class PlanVisit < ApplicationRecord
  belongs_to :user
  belongs_to :plan
  belongs_to :location

  validates :location_id, uniqueness: { scope: [ :user_id, :plan_id ] }
end
