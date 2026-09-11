# frozen_string_literal: true

require "test_helper"

module Ai
  class ReviewModeratorTest < ActiveJob::TestCase
    setup do
      @location = Location.create!(name: "Verdict Place", city: "Sarajevo", lat: 43.85, lng: 18.41)
      @review = @location.reviews.create!(rating: 1, comment: "Užasno mjesto, nikad više.", author_name: "Mirza")
      @location.reload
    end

    teardown do
      ReviewDeletion.delete_all
      @location.destroy
    end

    test "enqueues one request on the AI queue with itself as the callback" do
      assert_enqueued_with(job: OpenaiRequestJob, queue: "ai_generation") do
        Ai::ReviewModerator.enqueue(@review)
      end

      args = enqueued_jobs.last[:args].first
      assert_equal "Ai::ReviewModerator", args["callback_class"]
      assert_equal @review.id, args["callback_id"]
      assert_includes args["prompt"], @review.comment
      assert_includes args["prompt"], "Verdict Place"
      assert_equal %w[violation category confidence reason], args["schema"]["required"]
    end

    test "a confident violation hides the review and keeps the agent's verdict on it" do
      Ai::ReviewModerator.handle_openai_response(@review.id, violation: true, category: "slur", confidence: 0.97, reason: "Ethnic slur.")

      @review.reload
      assert @review.rejected?
      assert_equal "slur", @review.moderation_category
      assert_equal 0.97, @review.moderation_confidence
      assert_equal "Ethnic slur.", @review.moderation_reason
      assert_equal 0, @location.reload.reviews_count
      assert_equal 0, @location.average_rating
    end

    test "an unsure violation leaves the review for a curator" do
      Ai::ReviewModerator.handle_openai_response(@review.id, violation: true, category: "hate", confidence: 0.5, reason: "Might be irony.")

      @review.reload
      assert @review.pending?
      assert @review.flagged?
      assert_equal 0, @location.reload.reviews_count
    end

    test "an insult is a violation like any other" do
      Ai::ReviewModerator.handle_openai_response(@review.id, violation: true, category: "insult", confidence: 0.9, reason: "Name-calling.")

      @review.reload
      assert @review.rejected?
      assert_equal "insult", @review.moderation_category
    end

    test "a confident clean comment is published without a curator" do
      Ai::ReviewModerator.handle_openai_response(@review.id, violation: false, category: "clean", confidence: 0.99, reason: "A harsh but honest opinion.")

      @review.reload
      assert @review.approved?
      assert_equal 1, @location.reload.reviews_count
    end

    test "an unsure clean comment still waits for a curator" do
      Ai::ReviewModerator.handle_openai_response(@review.id, violation: false, category: "clean", confidence: 0.4, reason: "Hard to read.")

      @review.reload
      assert @review.pending?
      assert_not @review.flagged?
    end

    test "the flag threshold is a setting" do
      Setting.set("ai.moderation.flag_threshold", "0.4", type: "float", category: "ai")

      Ai::ReviewModerator.handle_openai_response(@review.id, violation: true, category: "spam", confidence: 0.5, reason: "Advertising.")

      assert @review.reload.rejected?
    ensure
      Setting.find_by(key: "ai.moderation.flag_threshold")&.destroy
    end

    test "no answer leaves the review pending" do
      assert_nil Ai::ReviewModerator.handle_openai_response(@review.id, nil)

      assert @review.reload.pending?
    end

    test "a review gone before the answer arrives is ignored" do
      @review.destroy!
      ReviewDeletion.delete_all

      assert_nil Ai::ReviewModerator.handle_openai_response(@review.id, violation: true, category: "slur", confidence: 0.99, reason: "Slur.")
    end
  end
end
