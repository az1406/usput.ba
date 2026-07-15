class AddCyclingInfoToExperiences < ActiveRecord::Migration[8.1]
  def change
    add_column :experiences, :cycling_distance_km, :decimal, precision: 6, scale: 2
    add_column :experiences, :cycling_elevation_gain, :integer
    add_column :experiences, :cycling_difficulty, :string
    add_column :experiences, :cycling_route_type, :string
    add_column :experiences, :bike_type, :string
  end
end
