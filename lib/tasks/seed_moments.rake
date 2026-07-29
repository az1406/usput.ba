# frozen_string_literal: true

require "net/http"

# Demo moments for existing locations. Kept out of db/seeds.rb on purpose:
# db:prepare seeds a freshly created database automatically, and this data
# should only ever arrive when someone asks for it.
namespace :seed do
  desc "Attach demo moments (private + public) to existing locations"
  task :moments, [ :per_location ] => :environment do |_t, args|
    per_location = (args[:per_location] || 2).to_i
    # Admins are how the product gets tested; seeded moments on their account
    # muddle what is real and what is demo data.
    authors = User.where.not(user_type: :admin).order(:id).to_a
    abort "No non-admin users to author moments." if authors.empty?

    locations = Location.with_coordinates.order(:id).to_a
    abort "No locations to attach moments to" if locations.empty?

    puts "#{locations.size} locations, up to #{per_location} moments each, authors: #{authors.map(&:username).join(', ')}"
    created = 0

    locations.each_with_index do |location, index|
      # Vary the count so the surfaces get exercised against thin and busy
      # locations alike, not a uniform grid.
      wanted = [ 2 + (location.id % 3), per_location, authors.size ].min
      wanted.times do |slot|
        author = authors[(index + slot) % authors.size]
        next if author.moments.exists?(location: location)

        moment = build_moment(author, location, slot)
        next unless moment

        # A visit is what earns the right to capture, so seeded moments carry
        # one or the surfaces disagree about whether the author was there.
        author.plan_visits.find_or_create_by!(plan: moment.plan, location: location)

        publish(moment) if (index + slot).odd?
        created += 1
        print "."
      end
    end

    puts
    report
  end

  def self.build_moment(author, location, slot)
    image = demo_image(seed: "moment_#{location.id}_#{slot}")
    return nil unless image

    moment = author.moments.build(plan: Plan.explore_bosnia_for(author), location: location)
    moment.photo.attach(image)
    moment.save!
    moment
  end

  # Publishing re-enters moderation (Moment#require_moderation_when_published),
  # so approval has to be a second write or nothing reaches Browse.
  def self.publish(moment)
    moment.update!(visibility: :public_moment)
    moment.update!(moderation_status: :approved)
  end

  def self.demo_image(seed:)
    uri = URI.parse("https://picsum.photos/seed/#{seed}/800/600")
    response = Net::HTTP.get_response(uri)
    response = Net::HTTP.get_response(URI.parse(response["location"])) if response.is_a?(Net::HTTPRedirection)
    return nil unless response.is_a?(Net::HTTPSuccess)

    sleep 0.3
    { io: StringIO.new(response.body), filename: "#{seed}.jpg", content_type: "image/jpeg" }
  rescue StandardError => e
    warn "  image download failed (#{seed}): #{e.message}"
    nil
  end

  def self.report
    puts "moments: #{Moment.count} " \
         "(private #{Moment.visibility_private_moment.count}, " \
         "public #{Moment.visibility_public_moment.count}, " \
         "approved #{Moment.approved.count})"
    puts "browse-indexed moments: #{Browse.moments.count}"
  end
end
