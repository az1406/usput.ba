class CreateReviewDeletions < ActiveRecord::Migration[8.1]
  def change
    create_table :review_deletions do |t|
      t.string :review_uuid, limit: 36, null: false
      t.references :reviewable, polymorphic: true
      t.references :user, foreign_key: { on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.integer :rating, null: false
      t.text :comment
      t.string :author_name
      t.integer :source, null: false, default: 0
      t.string :category
      t.float :confidence
      t.text :reason
      t.string :model
      t.timestamps
    end

    add_index :review_deletions, :review_uuid
  end
end
