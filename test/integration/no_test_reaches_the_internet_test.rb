# frozen_string_literal: true

require "test_helper"

# config/environments/test.rb blanks every third-party key so the suite cannot
# call out. Named, never read: a failure here must not print the key it found.
class NoTestReachesTheInternetTest < ActiveSupport::TestCase
  THIRD_PARTY_KEYS = %w[
    ANTHROPIC_API_KEY
    OPENAI_API_KEY
    GEMINI_API_KEY
    OPENROUTESERVICE_API_KEY
  ].freeze

  test "no third-party key is configured, so a missing stub fails instead of calling out" do
    configured = THIRD_PARTY_KEYS.select { |name| ENV[name].present? }

    assert_empty configured, "the suite must run with no third-party key set"
  end
end
