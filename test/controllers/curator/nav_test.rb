# frozen_string_literal: true

require "test_helper"

# The desktop bar and the mobile menu render the same routes in different
# markup. Moments once reached only the desktop one, so the moderation queue was
# unreachable on a phone and nothing failed. Paths come from curator_nav_groups
# rather than a second list, so a route added there is asserted automatically.
class Curator::NavTest < ActionDispatch::IntegrationTest
  setup do
    @curator = User.create!(username: "nav_curator", password: "password123", user_type: :curator)
    @admin = User.create!(username: "nav_admin", password: "password123", user_type: :admin)
  end

  teardown do
    @curator&.destroy
    @admin&.destroy
  end

  test "every nav route a curator sees reaches both navs" do
    login_as(@curator)
    get curator_root_path
    assert_response :success

    assert_reachable_in_both_navs
  end

  test "an admin's extra routes reach both navs too" do
    login_as(@admin)
    get curator_root_path
    assert_response :success

    assert_includes nav_paths, curator_admin_users_path
    assert_reachable_in_both_navs
  end

  test "the moments queue is one of them" do
    login_as(@curator)
    get curator_root_path

    assert_includes nav_paths, curator_moments_path
  end

  test "a curator sees no admin routes" do
    login_as(@curator)
    get curator_root_path

    assert_no_match(/href="#{Regexp.escape(curator_admin_users_path)}"/, response.body)
  end

  private

  def nav_paths
    @controller.view_context.curator_nav_groups.flat_map { |group| group[:items].pluck(:path) }
  end

  # Scoped to the nav element: the page body links to some of these routes too,
  # and a quick-action card is not a way to reach them on a phone.
  def assert_reachable_in_both_navs
    nav = response.body[/<nav\b.*?<\/nav>/m]
    assert nav, "no nav element rendered"

    nav_paths.each do |path|
      count = nav.scan(/href="#{Regexp.escape(path)}"/).size
      assert_equal 2, count, "#{path} should appear in the desktop nav and the mobile nav, found #{count}"
    end
  end

  def login_as(user)
    post login_path, params: { username: user.username, password: "password123" }
  end
end
