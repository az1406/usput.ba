class AddModerationToReviews < ActiveRecord::Migration[8.1]
  def up
    # Moderation: 0 = pending, 1 = approved, 2 = rejected
    add_column :reviews, :moderation_status, :integer, default: 0, null: false

    # The agent's verdict, kept on the review so the curator list can show why
    # a comment was flagged. Deletions keep their own copy on review_deletions.
    add_column :reviews, :moderation_category, :string
    add_column :reviews, :moderation_confidence, :float
    add_column :reviews, :moderation_reason, :text

    add_index :reviews, [ :reviewable_type, :reviewable_id, :moderation_status ],
              name: "index_reviews_on_reviewable_and_moderation"

    # Every review written before this migration was public the moment it saved.
    # Defaulting them to pending would empty every list on the site.
    up_only do
      execute "UPDATE reviews SET moderation_status = 1"
    end
  end

  def down
    remove_index :reviews, name: "index_reviews_on_reviewable_and_moderation"
    remove_column :reviews, :moderation_reason
    remove_column :reviews, :moderation_confidence
    remove_column :reviews, :moderation_category
    remove_column :reviews, :moderation_status
  end
end
