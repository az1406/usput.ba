# frozen_string_literal: true

require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @location = Location.create!(
      name: "Test Location",
      city: "Sarajevo",
      lat: 43.8563,
      lng: 18.4131
    )

    @valid_params = {
      reviewable: @location,
      rating: 4,
      comment: "Great place to visit!",
      author_name: "Test Reviewer"
    }
  end

  teardown do
    @location&.destroy
  end

  # === Validation tests ===

  test "valid review is saved" do
    review = Review.new(@valid_params)
    assert review.save
    review.destroy
  end

  test "reviewable is required" do
    review = Review.new(@valid_params.merge(reviewable: nil))
    assert_not review.valid?
  end

  test "rating is required" do
    review = Review.new(@valid_params.merge(rating: nil))
    assert_not review.valid?
  end

  test "rating must be between 1 and 5" do
    review = Review.new(@valid_params.merge(rating: 0))
    assert_not review.valid?

    review.rating = 6
    assert_not review.valid?

    review.rating = 3
    assert review.valid?
  end

  test "comment can be blank" do
    review = Review.new(@valid_params.merge(comment: nil))
    assert review.valid?
  end

  test "author_name can be blank" do
    review = Review.new(@valid_params.merge(author_name: nil))
    assert review.valid?
  end

  # === Polymorphic association tests ===

  test "can create review for location" do
    review = Review.create!(@valid_params)
    assert_equal "Location", review.reviewable_type
    assert_equal @location.id, review.reviewable_id
    review.destroy
  end

  test "can create review for experience" do
    experience = Experience.create!(title: "Test Experience")
    review = Review.create!(@valid_params.merge(reviewable: experience))

    assert_equal "Experience", review.reviewable_type
    assert_equal experience.id, review.reviewable_id

    review.destroy
    experience.destroy
  end

  test "can create review for plan" do
    plan = Plan.create!(title: "Test Plan", city_name: "Sarajevo")
    review = Review.create!(@valid_params.merge(reviewable: plan))

    assert_equal "Plan", review.reviewable_type
    assert_equal plan.id, review.reviewable_id

    review.destroy
    plan.destroy
  end

  # === Scope tests ===

  test "recent scope orders by created_at descending" do
    old_review = Review.create!(@valid_params.merge(author_name: "Old"))
    old_review.update_column(:created_at, 1.week.ago)

    new_review = Review.create!(@valid_params.merge(author_name: "New"))

    recent = Review.recent.to_a
    assert_equal new_review, recent.first

    old_review.destroy
    new_review.destroy
  end

  # === Rating statistics ===

  test "reviews update reviewable average_rating once approved" do
    review1 = Review.create!(@valid_params.merge(rating: 5))
    @location.reload
    assert_equal 0.0, @location.average_rating, "a pending comment must not move the score"

    review1.approved!
    @location.reload
    assert_equal 5.0, @location.average_rating

    review2 = Review.create!(@valid_params.merge(rating: 3, author_name: "Second"))
    review2.approved!
    @location.reload
    assert_equal 4.0, @location.average_rating

    review1.destroy
    review2.destroy
  end

  # === Edge cases ===

  test "review with long comment validates max length" do
    # Comment has max length of 1000 characters
    valid_comment = "Great! " * 142 # ~994 characters
    review = Review.new(@valid_params.merge(comment: valid_comment))
    assert review.valid?

    # Too long comment should be invalid
    too_long = "x" * 1001
    review2 = Review.new(@valid_params.merge(comment: too_long))
    assert_not review2.valid?
  end

  test "review with special characters in comment is saved" do
    review = Review.new(@valid_params.merge(
      comment: "Great place with <special> characters & \"quotes\" and 'apostrophes'"
    ))
    assert review.valid?
  end

  test "review with unicode comment is saved" do
    review = Review.new(@valid_params.merge(
      comment: "Predivno mjesto! Preporuka svima."
    ))
    assert review.valid?
  end

  test "a new comment is sent for moderation" do
    assert_enqueued_with(job: OpenaiRequestJob, queue: "ai_generation") do
      Review.create!(@valid_params)
    end

    assert_equal "Ai::ReviewModerator", enqueued_jobs.last[:args].first["callback_class"]
  end

  test "a moderation failure never blocks the comment" do
    Ai::OpenaiQueue.stub :enqueue, ->(**) { raise Ai::OpenaiQueue::RequestError, "API key is invalid." } do
      review = Review.create!(@valid_params)

      assert review.persisted?
      assert Review.exists?(review.id)
    end
  end

  test "destroying a review by hand records a manual deletion" do
    review = Review.create!(@valid_params)

    assert_difference "ReviewDeletion.count", 1 do
      review.destroy!
    end

    deletion = ReviewDeletion.last
    assert deletion.manual?
    assert_equal review.uuid, deletion.review_uuid
    assert_equal "Great place to visit!", deletion.comment
    assert_equal 4, deletion.rating
    assert_equal @location, deletion.reviewable
  ensure
    ReviewDeletion.delete_all
  end

  test "a review going down with its place is not a deletion" do
    place = Location.create!(name: "Doomed", city: "Mostar", lat: 43.34, lng: 17.81)
    place.reviews.create!(rating: 3, comment: "Fine.")

    assert_no_difference "ReviewDeletion.count" do
      place.destroy!
    end
  end

  test "a rating without a comment is not sent for moderation" do
    assert_no_enqueued_jobs do
      Review.create!(@valid_params.merge(comment: nil))
    end
  end
end
