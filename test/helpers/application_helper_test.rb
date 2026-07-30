# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # Curator-entered urls are rendered as hrefs, and Rails does not escape the
  # scheme, so anything but absolute http(s) has to come back nil.
  test "safe_external_url passes absolute http and https through" do
    assert_equal "https://example.com/a?b=c", safe_external_url("https://example.com/a?b=c")
    assert_equal "http://example.com", safe_external_url("http://example.com")
    assert_equal "https://example.com", safe_external_url("  https://example.com  ")
  end

  test "safe_external_url refuses anything that is not absolute http(s)" do
    [
      "javascript:alert(1)",
      "JavaScript:alert(1)",
      "data:text/html,<script>alert(1)</script>",
      "vbscript:msgbox(1)",
      "//evil.example.com",
      "/relative/path",
      "example.com",
      "http://",
      "",
      nil
    ].each { |value| assert_nil safe_external_url(value), "#{value.inspect} must not become an href" }
  end
end
