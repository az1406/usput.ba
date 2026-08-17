# frozen_string_literal: true

module CuratorHelper
  # The single source both navs render. A route listed once here reaches the
  # desktop bar and the mobile menu; listed nowhere, the layout test fails.
  def curator_nav_groups
    groups = [
      { key: "content", items: [
        { key: "locations", path: curator_locations_path },
        { key: "experiences", path: curator_experiences_path },
        { key: "plans", path: curator_plans_path }
      ] },
      { key: "media", items: [
        { key: "audio_tours", path: curator_audio_tours_path },
        { key: "photo_suggestions", path: curator_photo_suggestions_path }
      ] },
      { key: "workflow", items: [
        { key: "reviews", path: curator_reviews_path },
        { key: "proposals", path: curator_proposals_path },
        { key: "moments", path: curator_moments_path, default: "Moments" }
      ] }
    ]

    return groups unless current_user&.admin?

    groups << { key: "admin", admin: true, default: "Admin", items: [
      { key: "admin_content_changes", path: curator_admin_content_changes_path, default: "Sadržaj" },
      { key: "admin_curator_applications", path: curator_admin_curator_applications_path, default: "Prijave" },
      { key: "admin_photo_suggestions", path: curator_admin_photo_suggestions_path, default: "Fotografije" },
      { key: "admin_users", path: curator_admin_users_path, default: "Korisnici", divider: true }
    ] }
  end

  def curator_nav_label(entry)
    entry[:default] ? t("curator.nav.#{entry[:key]}", default: entry[:default]) : t("curator.nav.#{entry[:key]}")
  end

  def curator_nav_group_active?(group)
    group[:items].any? { |item| request.path.start_with?(item[:path]) }
  end

  # Generate a link path for a curator activity's recordable
  def activity_link_path(activity)
    return nil unless activity.recordable.present?

    case activity.recordable
    when Location
      curator_location_path(activity.recordable)
    when Experience
      curator_experience_path(activity.recordable)
    when Plan
      curator_plan_path(activity.recordable)
    when AudioTour
      curator_audio_tour_path(activity.recordable)
    when ContentChange
      curator_proposal_path(activity.recordable)
    when PhotoSuggestion
      curator_photo_suggestion_path(activity.recordable) if respond_to?(:curator_photo_suggestion_path)
    end
  rescue ActionController::UrlGenerationError
    nil
  end
end
