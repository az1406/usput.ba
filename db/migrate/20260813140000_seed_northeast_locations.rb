require "net/http"

# Eleven locations across Brčko, Gradačac, Orašje and Tuzla, added to a
# catalogue that had nothing in the northeast. Locations only: no moments, no
# reviews, no experiences.
#
# It runs on deploy rather than through db:seed because db/seeds.rb hardcodes
# `loc.city = "Sarajevo"` in its location loop and production never loads it.
#
# Additive and idempotent on the name: a place already in the catalogue is left
# exactly as it is, so a curator's edits are never overwritten and nothing here
# deletes or rewrites an existing row. Photo downloads are bounded by a timeout
# so an unreachable image host costs a picture, never the deploy.
class SeedNortheastLocations < ActiveRecord::Migration[8.1]
  LOCATIONS = [
    {
      name: "Ficibajr",
      city: "Brčko",
      lat: 44.8836, lng: 18.8003,
      description: "Brčko's stretch of Sava riverbank, and where the town goes when the weather is good. A swimming spot was made here in the late 1960s, and the park around it has grown into sports grounds, cafés and restaurants along a partly landscaped shore.",
      historical_context: "Brčko has the largest river port in Bosnia and Herzegovina, and life here has always faced the Sava. Ficibajr is the leisure side of that: the same river that carries the freight is the one the town swims in.",
      budget: :low,
      categories: [ "nature" ],
      tags: [ "sava", "river", "park", "swimming", "brcko" ],
      suitable_experiences: [ "nature", "sport" ]
    },
    {
      name: "Kula Husein-kapetana Gradaščevića",
      city: "Gradačac",
      lat: 44.878016, lng: 18.425551,
      description: "The tower at the heart of Gradačac fortress, and the town's landmark. It rises over the old centre with a clock tower beside it, and the walls around it took the better part of a century to finish.",
      historical_context: "Named for Husein-kapetan Gradaščević, the Zmaj od Bosne, who led the Bosnian uprising against Ottoman reform in 1831. The fortress was his seat, and it is the reason his name is still the first thing anyone says about Gradačac.",
      budget: :low,
      categories: [ "historical" ],
      tags: [ "fortress", "historic", "landmark", "ottoman", "zmaj-od-bosne" ],
      suitable_experiences: [ "history", "culture" ]
    },
    {
      name: "Franjevački samostan Tolisa",
      city: "Orašje",
      lat: 45.041667, lng: 18.645278,
      description: "A Franciscan monastery on the Posavina plain with the church of the Assumption beside it, and the Vrata Bosne museum inside. Its furniture is made from bog oak lifted out of the Sava riverbed, wood the river kept for thousands of years before anyone worked it.",
      historical_context: "Declared a national monument of Bosnia and Herzegovina in 2007. The monastery and parish have been the anchor of Catholic Posavina for generations, and its library and collections are the region's memory of itself.",
      budget: :low,
      categories: [ "religious" ],
      tags: [ "monastery", "national-monument", "museum", "posavina", "franciscan" ],
      suitable_experiences: [ "religious", "history", "culture", "art" ]
    },
    {
      name: "Azizija džamija",
      city: "Orašje",
      lat: 45.036229, lng: 18.693952,
      description: "A sultan's mosque in the centre of Orašje, begun in 1862 and in use a year later. It kept its original form through the war, and a restoration finished in 2024. Inside is a hair from the Prophet's beard, brought back from Mecca by a pilgrim and shown once a year, on the 27th night of Ramadan.",
      historical_context: "One of only 36 mosques in Bosnia and Herzegovina built on a sultan's direct order and at his expense. It went up for Bosniaks expelled from Serbia in 1862, who settled along the south bank of the Sava in two new towns named after Sultan Abdul Aziz — Gornja and Donja Azizija. Donja Azizija is Orašje.",
      budget: :low,
      categories: [ "religious" ],
      tags: [ "mosque", "historic", "ottoman", "national-heritage", "posavina" ],
      suitable_experiences: [ "religious", "history", "culture" ]
    },
    {
      name: "Ćevabdžinica Baća",
      city: "Orašje",
      lat: 45.036833, lng: 18.694561,
      description: "Ćevapi in the centre of Orašje, on Deseta ulica a few steps from the Azizija mosque. The kind of place a town keeps going back to rather than one that advertises.",
      historical_context: nil,
      budget: :low,
      categories: [ "restaurant" ],
      tags: [ "cevapi", "food", "orasje", "posavina" ],
      suitable_experiences: [ "food", "meat" ]
    },
    {
      name: "Kafe Kesten",
      city: "Orašje",
      lat: 45.0376735, lng: 18.6946294,
      description: "A café on the nasip, the embankment that holds the Sava back from Orašje. The water is Bosnia on one side and Croatia on the other, and the embankment is where the town walks in the evening.",
      historical_context: "The Sava has set the shape of Orašje for as long as there has been a town here — as border, as port, and as the thing the embankment exists to hold back.",
      budget: :low,
      categories: [ "restaurant" ],
      tags: [ "cafe", "sava", "nasip", "riverside", "orasje" ],
      suitable_experiences: [ "food" ]
    },
    {
      name: "Panonska jezera",
      city: "Tuzla",
      lat: 44.539517, lng: 18.680567,
      description: "The only inland salt lakes in Europe, in the middle of Tuzla's central park, drawing more than 350,000 people a year. Salt water to swim in, hundreds of kilometres from any sea.",
      historical_context: "The salt is not decoration. Tuzla sits on brine that has been worked since the neolithic, and the lakes are the modern face of the thing the city was built on and named after.",
      budget: :low,
      categories: [ "nature" ],
      tags: [ "salt-lakes", "swimming", "park", "tuzla", "unique" ],
      suitable_experiences: [ "nature", "sport", "wellness" ]
    },
    {
      name: "Soni trg",
      city: "Tuzla",
      lat: 44.5372, lng: 18.6759,
      description: "The salt square, in Tuzla's old centre. The city's name comes from the Turkish tuz — salt — and this square is where that trade sat.",
      historical_context: "Salt has been extracted around here since the neolithic, which makes Tuzla one of the oldest continuously settled places in Europe. Centuries of pumping brine from under the city also made the ground sink, and the old town has been settling into it ever since.",
      budget: :low,
      categories: [ "historical" ],
      tags: [ "square", "salt", "old-town", "tuzla", "historic" ],
      suitable_experiences: [ "history", "culture" ]
    },
    {
      name: "Kapija",
      city: "Tuzla",
      lat: 44.5378, lng: 18.6754,
      description: "A small square beside Soni trg, and the most serious place in Tuzla. A memorial stands where the shell landed.",
      historical_context: "On 25 May 1995 a shell fired from Ozren killed 71 young people gathered here on a spring evening, and wounded hundreds more. The memorial cemetery for them was built in 1999 at Slana banja, on the edge of the pine wood. The city marks the date every year.",
      budget: :low,
      categories: [ "historical" ],
      tags: [ "memorial", "history", "war", "tuzla", "square" ],
      suitable_experiences: [ "history", "culture" ]
    },
    {
      name: "Gazi Turali-begova džamija",
      city: "Tuzla",
      lat: 44.536426, lng: 18.679331,
      description: "Built in 1572 by Gazi Turali-beg, one of the founders of urban Tuzla, and known as the Poljska džamija because it went up in open field. A single-space mosque with a front mahfil, a stone minaret, and a dome worked into the flat ceiling — which is unusual enough to be the thing people come to see.",
      historical_context: "A national monument of Bosnia and Herzegovina. The salt workings under the city pulled the ground down around it: by the 1878 rebuilding the floor had dropped a full metre, and windows that had been the upper row became the lower one. It was raised again then, given a stone turbe around 1890, and last reopened after works in September 2014.",
      budget: :low,
      categories: [ "religious" ],
      tags: [ "mosque", "national-monument", "ottoman", "historic", "tuzla" ],
      suitable_experiences: [ "religious", "history", "culture", "art" ]
    },
    {
      name: "Restoran Zlatnik",
      city: "Tuzla",
      lat: 44.538275, lng: 18.685014,
      description: "A restaurant on the Slana banja promenade, a few steps from the salt lakes, on the walk between the park and the woods above the city.",
      historical_context: nil,
      budget: :medium,
      categories: [ "restaurant" ],
      tags: [ "restaurant", "slana-banja", "tuzla", "food" ],
      suitable_experiences: [ "food", "meat" ]
    }
  ].freeze

  def up
    enable_curator_actions

    created = []
    present = []
    blocked_by_mine_check = []

    LOCATIONS.each do |data|
      if Location.exists?(name: data[:name])
        present << data[:name]
        say "already in the catalogue, left alone: #{data[:name]}"
        next
      end

      location = build_northeast_location(data)
      location.save!
      assign_northeast_taxonomy(location, data)
      attach_northeast_photo(location)

      created << data[:name]
      say "created #{data[:name]} (#{data[:city]})"
    rescue ActiveRecord::RecordInvalid => e
      # Mine Checker is fail-closed (docs/mine_checker/SPEC.md §6): a blocked
      # coordinate is skipped and reported, never forced through.
      raise unless e.message.match?(/mine|minski|BHMAC/i)
      blocked_by_mine_check << data[:name]
      say "BLOCKED #{data[:name]} — mine check refused the coordinate"
    end

    say "seeded #{created.size}, #{present.size} already present"
    return if blocked_by_mine_check.empty?

    say "WARNING: #{blocked_by_mine_check.size} refused by the mine check: #{blocked_by_mine_check.join(', ')}"
  end

  # Only removes places nobody has been to. The destroy guard on Location
  # refuses any that hold a visit or a moment, so a rollback can never take a
  # traveller's record with it.
  def down
    Location.where(name: LOCATIONS.map { |d| d[:name] }).find_each do |location|
      say "kept #{location.name} — travellers have records there" unless location.destroy
    end
  end

  private

  # Edit, Delete and Archive all sit behind this flag in the curator action bar,
  # and Flipper keeps flags in the database — so on any environment where nobody
  # has run Flipper.enable by hand, the whole bar is invisible. Deploying should
  # be enough to see what was deployed.
  def enable_curator_actions
    return if Flipper.exist?(:curator_edit_delete)

    Flipper.enable(:curator_edit_delete)
    say "enabled the curator_edit_delete flag — Edit, Delete and Archive are visible"
  rescue StandardError => e
    say "could not set the curator_edit_delete flag: #{e.message}"
  end

  def build_northeast_location(data)
    Location.new(
      name: data[:name],
      description: data[:description],
      historical_context: data[:historical_context],
      lat: data[:lat],
      lng: data[:lng],
      city: data[:city],
      budget: data[:budget],
      tags: ((data[:tags] || []) + searchable_aliases(data)).uniq,
      suitable_experiences: data[:suitable_experiences] || []
    )
  end

  # Search runs on Postgres's `simple` config with no unaccent extension, so
  # "Orasje" does not match "Orašje" and a traveller typing on a plain keyboard
  # finds nothing. Carrying an unaccented form in the tags is the narrow fix for
  # these eleven; the general one is an unaccent extension over the whole
  # catalogue, which is a change to the search read-model and its own piece of
  # work. Only words that actually change are added — an ascii word is already
  # matched by its own text.
  def searchable_aliases(data)
    "#{data[:name]} #{data[:city]}".split(/[\s\-]+/).filter_map do |word|
      plain = ActiveSupport::Inflector.transliterate(word).downcase.gsub(/[^a-z0-9]/, "")
      next if plain.length < 3 || plain == word.downcase

      plain
    end.uniq
  end

  def assign_northeast_taxonomy(location, data)
    data[:categories].each do |key|
      location.add_category(key, primary: true) if LocationCategory.find_by_key(key)
    end
    data[:suitable_experiences].each do |key|
      type = ExperienceType.find_by(key: key)
      location.add_experience_type(type) if type
    end
  end

  # One placeholder photo each, the same picsum source db/seeds.rb uses. A
  # location with no photo is still a usable catalogue entry, so an unreachable
  # image host costs a picture rather than the whole run.
  def attach_northeast_photo(location)
    image = download_northeast_photo(seed: "loc_#{location.id}_0")
    return say("no photo for #{location.name} — image host unreachable") unless image

    location.photos.attach(image)
  end

  def download_northeast_photo(seed:, width: 800, height: 600)
    uri = URI.parse("https://picsum.photos/seed/#{seed}/#{width}/#{height}")
    response = fetch_with_timeout(uri)
    response = fetch_with_timeout(URI.parse(response["location"])) if response.is_a?(Net::HTTPRedirection)
    return nil unless response.is_a?(Net::HTTPSuccess)

    { io: StringIO.new(response.body), filename: "picsum_#{seed}.jpg", content_type: "image/jpeg" }
  rescue StandardError => e
    say "photo download failed: #{e.message}"
    nil
  end

  # A deploy must not wait on an image host.
  def fetch_with_timeout(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                    open_timeout: 5, read_timeout: 10) { |http| http.request(Net::HTTP::Get.new(uri)) }
  end
end
