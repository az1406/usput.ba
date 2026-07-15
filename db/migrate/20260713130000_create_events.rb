class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.text :info
      t.datetime :starts_at
      t.integer :duration
      t.references :location, null: false, foreign_key: true
      t.string :uuid, limit: 36, null: false

      t.timestamps
    end

    add_index :events, :uuid, unique: true
    add_index :events, :starts_at
  end
end
