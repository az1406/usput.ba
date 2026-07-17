# frozen_string_literal: true

require "test_helper"

class MomentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(username: "moment_owner", password: "password123")
    @other_user = User.create!(username: "moment_stranger", password: "password123")
    @location = Location.create!(name: "Moment Location", city: "Mostar", lat: 43.34, lng: 17.81)
    @plan = Plan.create!(title: "Moment Plan", city_name: "Mostar", visibility: :private_plan, user: @user)
  end

  teardown do
    @plan&.destroy
    @location&.destroy
    @user&.destroy
    @other_user&.destroy
  end

  test "valid moment is saved" do
    moment = build_moment

    assert moment.valid?
    assert moment.save
  end

  test "requires a photo" do
    moment = @user.moments.build(plan: @plan, location: @location)

    assert_not moment.valid?
    assert_includes moment.errors[:photo], "can't be blank"
  end

  test "rejects a non-image upload" do
    moment = build_moment(content_type: "application/pdf", filename: "not_a_photo.pdf")

    assert_not moment.valid?
    assert_includes moment.errors[:photo], "must be JPEG, PNG, GIF, or WebP"
  end

  test "rejects a note longer than 1000 characters" do
    moment = build_moment
    moment.note = "a" * 1001

    assert_not moment.valid?
  end

  test "generates a uuid and exposes it as the public id" do
    moment = build_moment
    moment.save!

    assert moment.uuid.present?
    assert_equal moment.uuid, moment.to_param
    assert_equal moment, Moment.find_by_public_id(moment.uuid)
  end

  test "the same location on two plans keeps two separate moments" do
    other_plan = Plan.create!(title: "Second Trip", city_name: "Mostar", visibility: :private_plan, user: @user)
    build_moment.save!
    build_moment(plan: other_plan).save!

    assert_equal 2, @user.moments.where(location: @location).count
  ensure
    other_plan&.destroy
  end

  test "is destroyed with its plan" do
    build_moment.save!

    assert_difference "Moment.count", -1 do
      @plan.destroy
    end
  end

  test "is destroyed with its user" do
    build_moment.save!

    assert_difference "Moment.count", -1 do
      @user.destroy
    end
  end

  test "another user's moments are not reachable through this user" do
    build_moment.save!

    assert_equal 0, @other_user.moments.count
  end

  private

  def build_moment(plan: @plan, content_type: "image/jpeg", filename: "moment.jpg")
    moment = @user.moments.build(plan: plan, location: @location)
    moment.photo.attach(
      io: StringIO.new("fake image data"),
      filename: filename,
      content_type: content_type
    )
    moment
  end
end
