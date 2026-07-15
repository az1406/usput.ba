# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "returns the translated label for a season key" do
    assert_equal "Summer", experience_season_label("summer")
    assert_equal "Spring", experience_season_label("spring")
  end

  test "translates the season key per locale" do
    I18n.with_locale(:bs) do
      assert_equal "Ljeto", experience_season_label("summer")
    end
  end

  # A blank key would resolve to the parent node and return the whole
  # { all_year: ..., spring: ... } Hash, which renders as raw text on the page.
  test "falls back to all_year for a blank season instead of returning the parent hash" do
    [ nil, "", "  " ].each do |blank|
      label = experience_season_label(blank)

      assert_kind_of String, label
      assert_equal "All year", label
    end
  end

  test "humanizes an unknown season key" do
    assert_equal "Monsoon", experience_season_label("monsoon")
  end

  test "returns the translated label for a location category key" do
    assert_equal "Place", location_type_label("place")
  end

  test "falls back to place for a blank location category" do
    assert_kind_of String, location_type_label(nil)
    assert_equal location_type_label("place"), location_type_label(nil)
  end
end
