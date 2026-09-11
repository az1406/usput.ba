# frozen_string_literal: true

require "test_helper"

class Curator::ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @curator = User.create!(username: "verdict_curator", password: "password123", user_type: :curator)
    @location = Location.create!(name: "Verdict Corner", city: "Sarajevo", lat: 43.85, lng: 18.41)
    @live = @location.reviews.create!(rating: 4, comment: "Lijepo mjesto.", author_name: "Mirza")
    @by_agent = ReviewDeletion.create!(
      review_uuid: SecureRandom.uuid, reviewable: @location, rating: 1, comment: "jebem ti mamu", author_name: "Konj",
      source: :agent, category: "insult", confidence: 0.99, reason: "Crude insult.", model: "claude-sonnet-4-5-20250929"
    )
    @by_curator = ReviewDeletion.create!(
      review_uuid: SecureRandom.uuid, reviewable: @location, rating: 5, comment: "Kupite bitcoin", author_name: "Bot",
      source: :curator, deleted_by: @curator, reason: "Spam."
    )
  end

  teardown do
    ReviewDeletion.delete_all
    @location.destroy
    @curator.destroy
  end

  test "the list shows live reviews and not the deleted ones" do
    login_as(@curator)

    get curator_reviews_path

    assert_response :success
    assert_match "Lijepo mjesto.", response.body
    assert_no_match "jebem ti mamu", response.body
  end

  test "the list says why a hidden comment was hidden" do
    @live.update!(moderation_status: :rejected, moderation_category: "insult",
                  moderation_confidence: 0.97, moderation_reason: "Name-calling.")
    login_as(@curator)

    get curator_reviews_path

    assert_response :success
    assert_match I18n.t("curator.reviews.hidden_as", category: I18n.t("curator.reviews.category.insult")), response.body
    assert_match "Name-calling.", response.body
  end

  test "the list says why an unsure comment is waiting" do
    @live.update!(moderation_status: :pending, moderation_category: "clean",
                  moderation_confidence: 0.4, moderation_reason: "Hard to read.")
    login_as(@curator)

    get curator_reviews_path

    assert_response :success
    assert_match I18n.t("curator.reviews.unsure", category: I18n.t("curator.reviews.category.clean")), response.body
  end

  test "the list says when no verdict has arrived" do
    @live.update!(moderation_status: :pending, moderation_category: nil,
                  moderation_confidence: nil, moderation_reason: nil)
    login_as(@curator)

    get curator_reviews_path

    assert_response :success
    assert_match I18n.t("curator.reviews.unchecked"), response.body
  end

  test "the deleted filter lists every deletion with who did it and why" do
    login_as(@curator)

    get curator_reviews_path(deleted: 1)

    assert_response :success
    assert_no_match "Lijepo mjesto.", response.body
    assert_match "jebem ti mamu", response.body
    assert_match "Deleted by the agent", response.body
    assert_match "Crude insult.", response.body
    assert_match "Kupite bitcoin", response.body
    assert_match "Deleted by verdict_curator", response.body
    assert_select "form[action=?]", curator_review_path(@live), count: 0
  end

  private

  def login_as(user)
    post login_path, params: { username: user.username, password: "password123" }
  end
end
