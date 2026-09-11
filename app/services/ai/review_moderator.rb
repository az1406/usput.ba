# frozen_string_literal: true

module Ai
  class ReviewModerator
    include Concerns::ErrorReporting
    include PromptHelper

    CATEGORIES = %w[clean slur hate harassment spam sexual insult other].freeze
    CLEAN = "clean"
    DEFAULT_FLAG_THRESHOLD = 0.85

    def self.enqueue(review)
      new(review).enqueue
    end

    def self.handle_openai_response(review_id, result)
      review = Review.find_by(id: review_id)
      return unless review

      new(review).apply(result)
    end

    def initialize(review)
      @review = review
    end

    def enqueue
      Ai::OpenaiQueue.enqueue(
        prompt: prompt,
        schema: schema,
        context: "ReviewModerator",
        callback_class: self.class.name,
        callback_id: @review.id
      )
    end

    # The agent no longer deletes. It records what it read and moves the review
    # out of pending only where policy says it may; a curator rules on the rest.
    def apply(result)
      if result.blank?
        log_warn "No verdict for review #{@review.id}; leaving it pending"
        return
      end

      @review.update!(
        moderation_category: result[:category],
        moderation_confidence: result[:confidence],
        moderation_reason: result[:reason],
        moderation_status: status_for(result)
      )
      log_info "Review #{@review.id} #{@review.moderation_status} (#{result[:category]}, #{result[:confidence]})"
      @review
    end

    private

    # An unsure verdict parks the comment rather than publishing it: a wrongly
    # hidden comment costs a curator one click, a wrongly published slur costs
    # the place its reputation.
    def status_for(result)
      return :rejected if violation?(result)
      return :approved if confidently_clean?(result)

      :pending
    end

    def confidently_clean?(result)
      !result[:violation] &&
        result[:category].to_s == CLEAN &&
        result[:confidence].to_f >= flag_threshold
    end

    def violation?(result)
      result[:violation] && result[:confidence].to_f >= flag_threshold
    end

    def flag_threshold
      Setting.get("ai.moderation.flag_threshold", default: DEFAULT_FLAG_THRESHOLD).to_f
    end

    def prompt
      load_prompt("review_moderator/review.md.erb",
        reviewable_kind: @review.reviewable_type.underscore.humanize.downcase,
        reviewable_name: @review.reviewable.try(:name) || @review.reviewable.try(:title),
        author_name: @review.author_name,
        rating: @review.rating,
        comment: @review.comment,
        categories: CATEGORIES.join(", "))
    end

    def schema
      {
        type: "object",
        properties: {
          violation: { type: "boolean" },
          category: { type: "string", enum: CATEGORIES },
          confidence: { type: "number" },
          reason: { type: "string" }
        },
        required: %w[violation category confidence reason],
        additionalProperties: false
      }
    end
  end
end
