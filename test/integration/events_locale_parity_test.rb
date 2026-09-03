# frozen_string_literal: true

require "test_helper"

# Missing translations do not raise in test, so a page renders in every locale
# whether or not its keys exist. Parity is asserted on the keys themselves.
class EventsLocaleParityTest < ActiveSupport::TestCase
  NAMESPACES = %w[events curator.events].freeze
  SINGLE_KEYS = %w[
    common.load_more nav.events curator.nav.events
    locations.show.upcoming_events locations.show.upcoming_events_in locations.show.all_events
  ].freeze

  test "every available locale carries every events key en has" do
    expected = NAMESPACES.flat_map { |ns| leaf_keys(I18n.t(ns, locale: :en, raise: true), ns) } + SINGLE_KEYS

    I18n.available_locales.each do |locale|
      missing = expected.reject { |key| defined_in(locale, key) }
      assert_empty missing, "#{locale} is missing #{missing.size} events keys"
    end
  end

  private

  # I18n.exists? answers through the fallback chain, so a key en has would
  # count as present everywhere. The loaded table for one locale does not.
  def defined_in(locale, key)
    !I18n.backend.translations.dig(locale, *key.split(".").map(&:to_sym)).nil?
  end

  def leaf_keys(hash, prefix)
    hash.flat_map do |key, value|
      path = "#{prefix}.#{key}"
      value.is_a?(Hash) ? leaf_keys(value, path) : [ path ]
    end
  end
end
