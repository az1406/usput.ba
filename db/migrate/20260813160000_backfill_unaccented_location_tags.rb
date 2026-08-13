# Search matches whole words against a Postgres text blob built from a
# location's title, description, tags and city, and the `unaccent` extension is
# not installed — so "Orasje" does not match "Orašje" and a traveller typing on
# a plain keyboard finds nothing. Carrying an unaccented form in the tags is the
# narrow fix; the general one is an unaccent extension over the whole catalogue.
#
# Backfills every location whose name or city carries a diacritic, so places
# created before the aliasing existed get it too. Only words that actually
# change are added — an ascii word is already matched by its own text.
class BackfillUnaccentedLocationTags < ActiveRecord::Migration[8.1]
  def up
    touched = 0

    Location.find_each do |location|
      aliases = unaccented_aliases(location)
      next if aliases.empty?

      merged = (location.tags + aliases).uniq
      next if merged == location.tags

      # update_column, not update!: this is a search alias, not a content edit,
      # and bumping updated_at would invalidate the map catalogue for every
      # client and re-sync every row through Browse for nothing.
      location.update_column(:tags, merged)
      touched += 1
    end

    # Browse holds its own copy of the searchable text, so the rows have to be
    # rebuilt or the tags never reach the index they exist for.
    Location.find_each { |location| Browse.sync_record(location) }

    say "added unaccented aliases to #{touched} location(s) and resynced the index"
  end

  def down
    # The aliases are indistinguishable from hand-written tags once merged;
    # removing them would take a curator's own tags with them.
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def unaccented_aliases(location)
    "#{location.name} #{location.city}".split(/[\s\-]+/).filter_map do |word|
      plain = ActiveSupport::Inflector.transliterate(word).downcase.gsub(/[^a-z0-9]/, "")
      next if plain.length < 3 || plain == word.downcase

      plain
    end.uniq
  end
end
