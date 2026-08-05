# Architecture Snapshot

## Repository Map

| Module | Language | Symbols | Exported |
|--------|----------|---------|----------|
| `.` | ruby | 0 | 0 |
| `app/controllers` | ruby | 157 | 94 |
| `app/controllers/concerns` | ruby | 39 | 8 |
| `app/controllers/curator` | ruby | 104 | 64 |
| `app/controllers/curator/admin` | ruby | 39 | 32 |
| `app/controllers/plans` | ruby | 7 | 3 |
| `app/helpers` | ruby | 34 | 32 |
| `app/jobs` | ruby | 3 | 3 |
| `app/mailers` | ruby | 1 | 1 |
| `app/models` | ruby | 293 | 246 |
| `app/models/concerns` | ruby | 25 | 23 |
| `app/services` | ruby | 79 | 41 |
| `app/services/ai` | ruby | 128 | 64 |
| `app/services/ai/concerns` | ruby | 10 | 3 |
| `app/services/ai/location_enricher` | ruby | 46 | 24 |
| `app/services/geo` | ruby | 11 | 7 |
| `app/services/maps` | ruby | 8 | 5 |
| `app/services/mine_checker` | ruby | 58 | 34 |
| `bin` | ruby | 4 | 4 |
| `config` | ruby | 2 | 2 |
| `config/environments` | ruby | 0 | 0 |
| `config/initializers` | ruby | 1 | 1 |
| `db` | ruby | 2 | 2 |
| `db/migrate` | ruby | 140 | 139 |
| `db/queue_migrate` | ruby | 2 | 2 |
| `lib` | ruby | 4 | 4 |
| `lib/platform` | ruby | 51 | 26 |
| `lib/platform/dsl` | ruby | 139 | 68 |
| `lib/platform/dsl/executors` | ruby | 166 | 46 |
| `lib/platform/services` | ruby | 15 | 12 |
| `lib/tasks` | ruby | 0 | 0 |
| `scripts/mine_checker` | ruby | 11 | 11 |
| `test` | ruby | 7 | 6 |
| `test/controllers` | ruby | 22 | 14 |
| `test/controllers/concerns` | ruby | 1 | 1 |
| `test/controllers/curator` | ruby | 15 | 6 |
| `test/controllers/curator/admin` | ruby | 10 | 5 |
| `test/db/migrate` | ruby | 2 | 2 |
| `test/helpers` | ruby | 2 | 2 |
| `test/integration` | ruby | 30 | 14 |
| `test/jobs` | ruby | 2 | 1 |
| `test/lib` | ruby | 1 | 1 |
| `test/lib/platform` | ruby | 4 | 3 |
| `test/lib/platform/dsl` | ruby | 15 | 15 |
| `test/lib/platform/dsl/executors` | ruby | 6 | 6 |
| `test/lib/platform/services` | ruby | 1 | 1 |
| `test/models` | ruby | 14 | 13 |
| `test/services` | ruby | 12 | 6 |
| `test/services/ai` | ruby | 25 | 10 |
| `test/services/ai/location_enricher` | ruby | 17 | 12 |
| `test/services/geo` | ruby | 1 | 1 |
| `test/services/mine_checker` | ruby | 3 | 3 |
| `test/support` | ruby | 9 | 9 |
| `test/system` | ruby | 45 | 40 |

## Extraction Quality

- Files parsed: **468** / 2418 seen (0 file(s) + 5 directory tree(s) skipped by ignore globs)
- Parse errors: 0
- Cross-repo analysis: not run (single-repo snapshot — append client/backend repos to enable unused-routes and coverage)

## Architecture Pattern

**Architecture pattern: rails-mvc** (confidence: 59%)

Detected rails-mvc architecture pattern with 59% confidence. Found 7 layers with 23 classified modules.

Layer mapping:
- module "app/controllers" maps to layer "controller"
- module "app/controllers/concerns" maps to layer "controller"
- module "app/controllers/curator" maps to layer "controller"
- module "app/controllers/curator/admin" maps to layer "controller"
- module "app/controllers/plans" maps to layer "controller"
- module "app/helpers" maps to layer "helper"
- module "app/jobs" maps to layer "job"
- module "app/mailers" maps to layer "mailer"
- module "app/models" maps to layer "model"
- module "app/models/concerns" maps to layer "model"
- module "app/services" maps to layer "service"
- module "app/services/ai" maps to layer "service"
- module "app/services/ai/concerns" maps to layer "service"
- module "app/services/ai/location_enricher" maps to layer "service"
- module "app/services/geo" maps to layer "service"
- module "app/services/maps" maps to layer "service"
- module "app/services/mine_checker" maps to layer "service"
- module "lib" maps to layer "lib"
- module "lib/platform" maps to layer "lib"
- module "lib/platform/dsl" maps to layer "lib"
- module "lib/platform/dsl/executors" maps to layer "lib"
- module "lib/platform/services" maps to layer "service"
- module "lib/tasks" maps to layer "lib"

## Entry Points

- **handler**: `Platform::MCPServer.production_guard!` (lib/platform/mcp_server.rb)
- **handler**: `Platform::MCPServer.run` (lib/platform/mcp_server.rb)
- **route** DELETE `/curator/audio_tours/:id` (config/routes.rb)
- **route** DELETE `/curator/experiences/:id` (config/routes.rb)
- **route** DELETE `/curator/locations/:id` (config/routes.rb)
- **route** DELETE `/curator/plans/:id` (config/routes.rb)
- **route** DELETE `/curator/reviews/:id` (config/routes.rb)
- **route** DELETE `/logout` (config/routes.rb)
- **route** DELETE `/plans/:plan_id/moments/:id` (config/routes.rb)
- **route** DELETE `/plans/:plan_id/visits/:id` (config/routes.rb)
- **route** DELETE `/profile/avatar` (config/routes.rb)
- **route** DELETE `/user/plans/:id` (config/routes.rb)
- **route** GET `/` (config/routes.rb)
- **route** GET `/become-curator` (config/routes.rb)
- **route** GET `/curator/` (config/routes.rb)
- **route** GET `/curator/admin/content_changes/:id` (config/routes.rb)
- **route** GET `/curator/admin/content_changes` (config/routes.rb)
- **route** GET `/curator/admin/curator_applications/:id` (config/routes.rb)
- **route** GET `/curator/admin/curator_applications` (config/routes.rb)
- **route** GET `/curator/admin/photo_suggestions/:id` (config/routes.rb)
- **route** GET `/curator/admin/photo_suggestions` (config/routes.rb)
- **route** GET `/curator/admin/users/:id/edit` (config/routes.rb)
- **route** GET `/curator/admin/users/:id` (config/routes.rb)
- **route** GET `/curator/admin/users` (config/routes.rb)
- **route** GET `/curator/audio_tours/:id/edit` (config/routes.rb)
- **route** GET `/curator/audio_tours/:id` (config/routes.rb)
- **route** GET `/curator/audio_tours/new` (config/routes.rb)
- **route** GET `/curator/audio_tours` (config/routes.rb)
- **route** GET `/curator/experiences/:id/edit` (config/routes.rb)
- **route** GET `/curator/experiences/:id` (config/routes.rb)
- **route** GET `/curator/experiences/new` (config/routes.rb)
- **route** GET `/curator/experiences` (config/routes.rb)
- **route** GET `/curator/locations/:id/edit` (config/routes.rb)
- **route** GET `/curator/locations/:id` (config/routes.rb)
- **route** GET `/curator/locations/:location_id/photo_suggestions/new` (config/routes.rb)
- **route** GET `/curator/locations/needs_photos` (config/routes.rb)
- **route** GET `/curator/locations/new` (config/routes.rb)
- **route** GET `/curator/locations` (config/routes.rb)
- **route** GET `/curator/moments/:id/photo` (config/routes.rb)
- **route** GET `/curator/moments` (config/routes.rb)
- **route** GET `/curator/photo_suggestions/:id` (config/routes.rb)
- **route** GET `/curator/photo_suggestions` (config/routes.rb)
- **route** GET `/curator/plans/:id/edit` (config/routes.rb)
- **route** GET `/curator/plans/:id` (config/routes.rb)
- **route** GET `/curator/plans/new` (config/routes.rb)
- **route** GET `/curator/plans` (config/routes.rb)
- **route** GET `/curator/proposals/:id` (config/routes.rb)
- **route** GET `/curator/proposals` (config/routes.rb)
- **route** GET `/curator/reviews/:id` (config/routes.rb)
- **route** GET `/curator/reviews` (config/routes.rb)
- **route** GET `/curator_applications/:id` (config/routes.rb)
- **route** GET `/curator_applications/new` (config/routes.rb)
- **route** GET `/experiences/:experience_id/reviews` (config/routes.rb)
- **route** GET `/experiences/:id` (config/routes.rb)
- **route** GET `/explore-bosnia/:category` (config/routes.rb)
- **route** GET `/explore-bosnia` (config/routes.rb)
- **route** GET `/explore` (config/routes.rb)
- **route** GET `/imprint` (config/routes.rb)
- **route** GET `/locations/:id/audio_tour` (config/routes.rb)
- **route** GET `/locations/:id/map_panel` (config/routes.rb)
- **route** GET `/locations/:id` (config/routes.rb)
- **route** GET `/locations/:location_id/moments` (config/routes.rb)
- **route** GET `/locations/:location_id/reviews` (config/routes.rb)
- **route** GET `/locations/map_points` (config/routes.rb)
- **route** GET `/login` (config/routes.rb)
- **route** GET `/manifest` (config/routes.rb)
- **route** GET `/mine-check/areas` (config/routes.rb)
- **route** GET `/mine-check` (config/routes.rb)
- **route** GET `/minesweeper` (config/routes.rb)
- **route** GET `/new/home` (config/routes.rb)
- **route** GET `/plans/:id/start` (config/routes.rb)
- **route** GET `/plans/:id` (config/routes.rb)
- **route** GET `/plans/:plan_id/moments/:id/photo` (config/routes.rb)
- **route** GET `/plans/:plan_id/moments` (config/routes.rb)
- **route** GET `/plans/:plan_id/reviews` (config/routes.rb)
- **route** GET `/plans/recommendations` (config/routes.rb)
- **route** GET `/plans/search_cities` (config/routes.rb)
- **route** GET `/plans/view` (config/routes.rb)
- **route** GET `/plans/wizard/:city_slug` (config/routes.rb)
- **route** GET `/plans/wizard` (config/routes.rb)
- **route** GET `/plans` (config/routes.rb)
- **route** GET `/privacy` (config/routes.rb)
- **route** GET `/profile/plans` (config/routes.rb)
- **route** GET `/profile` (config/routes.rb)
- **route** GET `/register` (config/routes.rb)
- **route** GET `/route` (config/routes.rb)
- **route** GET `/service-worker` (config/routes.rb)
- **route** GET `/terms` (config/routes.rb)
- **route** GET `/up` (config/routes.rb)
- **route** GET `/user/plans/:id/edit` (config/routes.rb)
- **route** GET `/user/plans/:id` (config/routes.rb)
- **route** GET `/user/plans/new` (config/routes.rb)
- **route** GET `/user/plans` (config/routes.rb)
- **route** GET `/v1/voices` (app/services/ai/audio_tour_generator.rb)
- **route** PATCH `/curator/admin/users/:id` (config/routes.rb)
- **route** PATCH `/curator/audio_tours/:id` (config/routes.rb)
- **route** PATCH `/curator/experiences/:id` (config/routes.rb)
- **route** PATCH `/curator/locations/:id` (config/routes.rb)
- **route** PATCH `/curator/plans/:id` (config/routes.rb)
- **route** PATCH `/plans/:plan_id/moments/:id/publish` (config/routes.rb)
- **route** PATCH `/plans/:plan_id/moments/:id/unpublish` (config/routes.rb)
- **route** PATCH `/profile/avatar` (config/routes.rb)
- **route** PATCH `/travel_profile` (config/routes.rb)
- **route** PATCH `/user/plans/:id` (config/routes.rb)
- **route** POST `/curator/admin/content_changes/:id/approve` (config/routes.rb)
- **route** POST `/curator/admin/content_changes/:id/reject` (config/routes.rb)
- **route** POST `/curator/admin/curator_applications/:id/approve` (config/routes.rb)
- **route** POST `/curator/admin/curator_applications/:id/reject` (config/routes.rb)
- **route** POST `/curator/admin/photo_suggestions/:id/approve` (config/routes.rb)
- **route** POST `/curator/admin/photo_suggestions/:id/reject` (config/routes.rb)
- **route** POST `/curator/admin/users/:id/unblock` (config/routes.rb)
- **route** POST `/curator/audio_tours` (config/routes.rb)
- **route** POST `/curator/experiences` (config/routes.rb)
- **route** POST `/curator/locations/:location_id/photo_suggestions` (config/routes.rb)
- **route** POST `/curator/locations` (config/routes.rb)
- **route** POST `/curator/moments/:id/approve` (config/routes.rb)
- **route** POST `/curator/moments/:id/reject` (config/routes.rb)
- **route** POST `/curator/plans` (config/routes.rb)
- **route** POST `/curator/proposals/:id/add_review` (config/routes.rb)
- **route** POST `/curator_applications` (config/routes.rb)
- **route** POST `/experiences/:experience_id/reviews` (config/routes.rb)
- **route** POST `/locations/:location_id/reviews` (config/routes.rb)
- **route** POST `/login` (config/routes.rb)
- **route** POST `/mine-check/check` (config/routes.rb)
- **route** POST `/plans/:plan_id/moments` (config/routes.rb)
- **route** POST `/plans/:plan_id/reviews` (config/routes.rb)
- **route** POST `/plans/:plan_id/visits` (config/routes.rb)
- **route** POST `/plans/find_city` (config/routes.rb)
- **route** POST `/plans/generate` (config/routes.rb)
- **route** POST `/register` (config/routes.rb)
- **route** POST `/travel_profile/sync` (config/routes.rb)
- **route** POST `/user/plans/:id/toggle_visibility` (config/routes.rb)
- **route** POST `/user/plans/share` (config/routes.rb)
- **route** POST `/user/plans/sync` (config/routes.rb)
- **route** POST `/user/plans` (config/routes.rb)
- **route** POST `/v1/audio/speech` (app/services/ai/audio_tour_generator.rb)
- **route** POST `/v1/text-to-speech/{}` (app/services/ai/audio_tour_generator.rb)
- **route** POST `/v2/directions/{}/geojson` (app/services/maps/route_fetcher.rb)
- **route** PUT `/curator/admin/users/:id` (config/routes.rb)
- **route** PUT `/curator/audio_tours/:id` (config/routes.rb)
- **route** PUT `/curator/experiences/:id` (config/routes.rb)
- **route** PUT `/curator/locations/:id` (config/routes.rb)
- **route** PUT `/curator/plans/:id` (config/routes.rb)
- **route** PUT `/travel_profile` (config/routes.rb)
- **route** PUT `/user/plans/:id` (config/routes.rb)

## Routes

| Method | Path | File | Type |
|--------|------|------|------|
| GET | `/` | `config/routes.rb` |  |
| GET | `/become-curator` | `config/routes.rb` |  |
| GET | `/curator/` | `config/routes.rb` |  |
| GET | `/curator/admin/content_changes` | `config/routes.rb` |  |
| GET | `/curator/admin/content_changes/:id` | `config/routes.rb` |  |
| POST | `/curator/admin/content_changes/:id/approve` | `config/routes.rb` |  |
| POST | `/curator/admin/content_changes/:id/reject` | `config/routes.rb` |  |
| GET | `/curator/admin/curator_applications` | `config/routes.rb` |  |
| GET | `/curator/admin/curator_applications/:id` | `config/routes.rb` |  |
| POST | `/curator/admin/curator_applications/:id/approve` | `config/routes.rb` |  |
| POST | `/curator/admin/curator_applications/:id/reject` | `config/routes.rb` |  |
| GET | `/curator/admin/photo_suggestions` | `config/routes.rb` |  |
| GET | `/curator/admin/photo_suggestions/:id` | `config/routes.rb` |  |
| POST | `/curator/admin/photo_suggestions/:id/approve` | `config/routes.rb` |  |
| POST | `/curator/admin/photo_suggestions/:id/reject` | `config/routes.rb` |  |
| GET | `/curator/admin/users` | `config/routes.rb` |  |
| GET | `/curator/admin/users/:id` | `config/routes.rb` |  |
| PATCH | `/curator/admin/users/:id` | `config/routes.rb` |  |
| PUT | `/curator/admin/users/:id` | `config/routes.rb` |  |
| GET | `/curator/admin/users/:id/edit` | `config/routes.rb` |  |
| POST | `/curator/admin/users/:id/unblock` | `config/routes.rb` |  |
| POST | `/curator/audio_tours` | `config/routes.rb` |  |
| GET | `/curator/audio_tours` | `config/routes.rb` |  |
| GET | `/curator/audio_tours/:id` | `config/routes.rb` |  |
| PATCH | `/curator/audio_tours/:id` | `config/routes.rb` |  |
| PUT | `/curator/audio_tours/:id` | `config/routes.rb` |  |
| DELETE | `/curator/audio_tours/:id` | `config/routes.rb` |  |
| GET | `/curator/audio_tours/:id/edit` | `config/routes.rb` |  |
| GET | `/curator/audio_tours/new` | `config/routes.rb` |  |
| POST | `/curator/experiences` | `config/routes.rb` |  |
| GET | `/curator/experiences` | `config/routes.rb` |  |
| PUT | `/curator/experiences/:id` | `config/routes.rb` |  |
| GET | `/curator/experiences/:id` | `config/routes.rb` |  |
| PATCH | `/curator/experiences/:id` | `config/routes.rb` |  |
| DELETE | `/curator/experiences/:id` | `config/routes.rb` |  |
| GET | `/curator/experiences/:id/edit` | `config/routes.rb` |  |
| GET | `/curator/experiences/new` | `config/routes.rb` |  |
| POST | `/curator/locations` | `config/routes.rb` |  |
| GET | `/curator/locations` | `config/routes.rb` |  |
| GET | `/curator/locations/:id` | `config/routes.rb` |  |
| DELETE | `/curator/locations/:id` | `config/routes.rb` |  |
| PUT | `/curator/locations/:id` | `config/routes.rb` |  |
| PATCH | `/curator/locations/:id` | `config/routes.rb` |  |
| GET | `/curator/locations/:id/edit` | `config/routes.rb` |  |
| POST | `/curator/locations/:location_id/photo_suggestions` | `config/routes.rb` |  |
| GET | `/curator/locations/:location_id/photo_suggestions/new` | `config/routes.rb` |  |
| GET | `/curator/locations/needs_photos` | `config/routes.rb` |  |
| GET | `/curator/locations/new` | `config/routes.rb` |  |
| GET | `/curator/moments` | `config/routes.rb` |  |
| POST | `/curator/moments/:id/approve` | `config/routes.rb` |  |
| GET | `/curator/moments/:id/photo` | `config/routes.rb` |  |
| POST | `/curator/moments/:id/reject` | `config/routes.rb` |  |
| GET | `/curator/photo_suggestions` | `config/routes.rb` |  |
| GET | `/curator/photo_suggestions/:id` | `config/routes.rb` |  |
| POST | `/curator/plans` | `config/routes.rb` |  |
| GET | `/curator/plans` | `config/routes.rb` |  |
| PATCH | `/curator/plans/:id` | `config/routes.rb` |  |
| PUT | `/curator/plans/:id` | `config/routes.rb` |  |
| GET | `/curator/plans/:id` | `config/routes.rb` |  |
| DELETE | `/curator/plans/:id` | `config/routes.rb` |  |
| GET | `/curator/plans/:id/edit` | `config/routes.rb` |  |
| GET | `/curator/plans/new` | `config/routes.rb` |  |
| GET | `/curator/proposals` | `config/routes.rb` |  |
| GET | `/curator/proposals/:id` | `config/routes.rb` |  |
| POST | `/curator/proposals/:id/add_review` | `config/routes.rb` |  |
| GET | `/curator/reviews` | `config/routes.rb` |  |
| GET | `/curator/reviews/:id` | `config/routes.rb` |  |
| DELETE | `/curator/reviews/:id` | `config/routes.rb` |  |
| POST | `/curator_applications` | `config/routes.rb` |  |
| GET | `/curator_applications/:id` | `config/routes.rb` |  |
| GET | `/curator_applications/new` | `config/routes.rb` |  |
| GET | `/experiences/:experience_id/reviews` | `config/routes.rb` |  |
| POST | `/experiences/:experience_id/reviews` | `config/routes.rb` |  |
| GET | `/experiences/:id` | `config/routes.rb` |  |
| GET | `/explore` | `config/routes.rb` |  |
| GET | `/explore-bosnia` | `config/routes.rb` |  |
| GET | `/explore-bosnia/:category` | `config/routes.rb` |  |
| GET | `/imprint` | `config/routes.rb` |  |
| GET | `/locations/:id` | `config/routes.rb` |  |
| GET | `/locations/:id/audio_tour` | `config/routes.rb` |  |
| GET | `/locations/:id/map_panel` | `config/routes.rb` |  |
| GET | `/locations/:location_id/moments` | `config/routes.rb` |  |
| GET | `/locations/:location_id/reviews` | `config/routes.rb` |  |
| POST | `/locations/:location_id/reviews` | `config/routes.rb` |  |
| GET | `/locations/map_points` | `config/routes.rb` |  |
| GET | `/login` | `config/routes.rb` |  |
| POST | `/login` | `config/routes.rb` |  |
| DELETE | `/logout` | `config/routes.rb` |  |
| GET | `/manifest` | `config/routes.rb` |  |
| GET | `/mine-check` | `config/routes.rb` |  |
| GET | `/mine-check/areas` | `config/routes.rb` |  |
| POST | `/mine-check/check` | `config/routes.rb` |  |
| GET | `/minesweeper` | `config/routes.rb` |  |
| GET | `/new/home` | `config/routes.rb` |  |
| GET | `/plans` | `config/routes.rb` |  |
| GET | `/plans/:id` | `config/routes.rb` |  |
| GET | `/plans/:id/start` | `config/routes.rb` |  |
| POST | `/plans/:plan_id/moments` | `config/routes.rb` |  |
| GET | `/plans/:plan_id/moments` | `config/routes.rb` |  |
| DELETE | `/plans/:plan_id/moments/:id` | `config/routes.rb` |  |
| GET | `/plans/:plan_id/moments/:id/photo` | `config/routes.rb` |  |
| PATCH | `/plans/:plan_id/moments/:id/publish` | `config/routes.rb` |  |
| PATCH | `/plans/:plan_id/moments/:id/unpublish` | `config/routes.rb` |  |
| POST | `/plans/:plan_id/reviews` | `config/routes.rb` |  |
| GET | `/plans/:plan_id/reviews` | `config/routes.rb` |  |
| POST | `/plans/:plan_id/visits` | `config/routes.rb` |  |
| DELETE | `/plans/:plan_id/visits/:id` | `config/routes.rb` |  |
| POST | `/plans/find_city` | `config/routes.rb` |  |
| POST | `/plans/generate` | `config/routes.rb` |  |
| GET | `/plans/recommendations` | `config/routes.rb` |  |
| GET | `/plans/search_cities` | `config/routes.rb` |  |
| GET | `/plans/view` | `config/routes.rb` |  |
| GET | `/plans/wizard` | `config/routes.rb` |  |
| GET | `/plans/wizard/:city_slug` | `config/routes.rb` |  |
| GET | `/privacy` | `config/routes.rb` |  |
| GET | `/profile` | `config/routes.rb` |  |
| DELETE | `/profile/avatar` | `config/routes.rb` |  |
| PATCH | `/profile/avatar` | `config/routes.rb` |  |
| GET | `/profile/plans` | `config/routes.rb` |  |
| GET | `/register` | `config/routes.rb` |  |
| POST | `/register` | `config/routes.rb` |  |
| GET | `/route` | `config/routes.rb` |  |
| GET | `/service-worker` | `config/routes.rb` |  |
| GET | `/terms` | `config/routes.rb` |  |
| PUT | `/travel_profile` | `config/routes.rb` |  |
| PATCH | `/travel_profile` | `config/routes.rb` |  |
| POST | `/travel_profile/sync` | `config/routes.rb` |  |
| GET | `/up` | `config/routes.rb` |  |
| POST | `/user/plans` | `config/routes.rb` |  |
| GET | `/user/plans` | `config/routes.rb` |  |
| PUT | `/user/plans/:id` | `config/routes.rb` |  |
| GET | `/user/plans/:id` | `config/routes.rb` |  |
| DELETE | `/user/plans/:id` | `config/routes.rb` |  |
| PATCH | `/user/plans/:id` | `config/routes.rb` |  |
| GET | `/user/plans/:id/edit` | `config/routes.rb` |  |
| POST | `/user/plans/:id/toggle_visibility` | `config/routes.rb` |  |
| GET | `/user/plans/new` | `config/routes.rb` |  |
| POST | `/user/plans/share` | `config/routes.rb` |  |
| POST | `/user/plans/sync` | `config/routes.rb` |  |
| POST | `/v1/audio/speech` | `app/services/ai/audio_tour_generator.rb` |  |
| POST | `/v1/text-to-speech/{}` | `app/services/ai/audio_tour_generator.rb` |  |
| GET | `/v1/voices` | `app/services/ai/audio_tour_generator.rb` |  |
| POST | `/v2/directions/{}/geojson` | `app/services/maps/route_fetcher.rb` |  |

## Storage

| Name | Kind | Operation | File |
|------|------|-----------|------|
| `AiGeneration` | model |  | `app/models/ai_generation.rb` |
| `ApplicationRecord` | model |  | `app/models/application_record.rb` |
| `AudioTour` | model |  | `app/models/audio_tour.rb` |
| `Browse` | model |  | `app/models/browse.rb` |
| `ContentChange` | model |  | `app/models/content_change.rb` |
| `ContentChangeContribution` | model |  | `app/models/content_change_contribution.rb` |
| `CuratorActivity` | model |  | `app/models/curator_activity.rb` |
| `CuratorApplication` | model |  | `app/models/curator_application.rb` |
| `CuratorReview` | model |  | `app/models/curator_review.rb` |
| `Experience` | model |  | `app/models/experience.rb` |
| `ExperienceCategory` | model |  | `app/models/experience_category.rb` |
| `ExperienceCategoryType` | model |  | `app/models/experience_category_type.rb` |
| `ExperienceLocation` | model |  | `app/models/experience_location.rb` |
| `ExperienceType` | model |  | `app/models/experience_type.rb` |
| `Locale` | model |  | `app/models/locale.rb` |
| `Location` | model |  | `app/models/location.rb` |
| `LocationCategory` | model |  | `app/models/location_category.rb` |
| `LocationCategoryAssignment` | model |  | `app/models/location_category_assignment.rb` |
| `LocationExperienceType` | model |  | `app/models/location_experience_type.rb` |
| `MineCheckAudit` | model |  | `app/models/mine_check_audit.rb` |
| `Moment` | model |  | `app/models/moment.rb` |
| `PhotoSuggestion` | model |  | `app/models/photo_suggestion.rb` |
| `Plan` | model |  | `app/models/plan.rb` |
| `PlanExperience` | model |  | `app/models/plan_experience.rb` |
| `PlanLocation` | model |  | `app/models/plan_location.rb` |
| `PlanVisit` | model |  | `app/models/plan_visit.rb` |
| `Review` | model |  | `app/models/review.rb` |
| `Setting` | model |  | `app/models/setting.rb` |
| `Translation` | model |  | `app/models/translation.rb` |
| `User` | model |  | `app/models/user.rb` |

## Dependency Rules

- `.` -> `config`
- `app/controllers/concerns` -> `app/models`
- `app/controllers/concerns` -> `app/services`
- `app/controllers/curator/admin` -> `app/controllers/curator`
- `app/controllers/curator/admin` -> `app/models`
- `app/controllers/curator` -> `app/controllers/concerns`
- `app/controllers/curator` -> `app/controllers`
- `app/controllers/curator` -> `app/models`
- `app/controllers/curator` -> `test`
- `app/controllers/plans` -> `app/controllers/concerns`
- `app/controllers/plans` -> `app/controllers`
- `app/controllers/plans` -> `app/models`
- `app/controllers/plans` -> `test`
- `app/controllers` -> `app/controllers/concerns`
- `app/controllers` -> `app/models`
- `app/controllers` -> `app/services/ai/location_enricher`
- `app/controllers` -> `app/services/maps`
- `app/controllers` -> `app/services/mine_checker`
- `app/controllers` -> `test`
- `app/helpers` -> `test`
- `app/jobs` -> `app/services/ai/location_enricher`
- `app/jobs` -> `app/services/ai`
- `app/mailers` -> `app/services/ai/location_enricher`
- `app/models/concerns` -> `app/models`
- `app/models` -> `app/models/concerns`
- `app/models` -> `app/services/ai/location_enricher`
- `app/models` -> `app/services/mine_checker`
- `app/models` -> `app/services`
- `app/models` -> `test`
- `app/services/ai/location_enricher` -> `app/helpers`
- `app/services/ai/location_enricher` -> `app/models`
- `app/services/ai/location_enricher` -> `app/services/ai/concerns`
- `app/services/ai/location_enricher` -> `app/services/ai`
- `app/services/ai` -> `app/helpers`
- `app/services/ai` -> `app/jobs`
- `app/services/ai` -> `app/models`
- `app/services/ai` -> `app/services/ai/concerns`
- `app/services/ai` -> `app/services/ai/location_enricher`
- `app/services/ai` -> `app/services`
- `app/services/ai` -> `test`
- `app/services/mine_checker` -> `app/models`
- `app/services` -> `app/models`
- `app/services` -> `app/services/ai/location_enricher`
- `app/services` -> `test`
- `bin` -> `config`
- `db/migrate` -> `app/models`
- `db/migrate` -> `test`
- `lib/platform/dsl/executors` -> `app/models`
- `lib/platform/dsl/executors` -> `app/services/ai/location_enricher`
- `lib/platform/dsl/executors` -> `app/services/ai`
- `lib/platform/dsl/executors` -> `app/services/geo`
- `lib/platform/dsl/executors` -> `app/services`
- `lib/platform/dsl/executors` -> `lib/platform/dsl`
- `lib/platform/dsl/executors` -> `lib/platform/services`
- `lib/platform/dsl/executors` -> `test`
- `lib/platform/dsl` -> `app/models`
- `lib/platform/dsl` -> `app/services/geo`
- `lib/platform/dsl` -> `app/services`
- `lib/platform/dsl` -> `lib/platform/dsl/executors`
- `lib/platform/dsl` -> `test`
- `lib/platform/services` -> `app/models`
- `lib/platform` -> `app/services/ai/location_enricher`
- `lib/platform` -> `lib/platform/dsl`
- `lib/platform` -> `lib`
- `test/controllers/concerns` -> `app/models`
- `test/controllers/curator/admin` -> `app/models`
- `test/controllers/curator/admin` -> `test`
- `test/controllers/curator` -> `app/models`
- `test/controllers/curator` -> `test`
- `test/controllers` -> `app/controllers`
- `test/controllers` -> `app/models`
- `test/controllers` -> `app/services/maps`
- `test/controllers` -> `app/services/mine_checker`
- `test/controllers` -> `test/support`
- `test/controllers` -> `test`
- `test/db/migrate` -> `app/models`
- `test/db/migrate` -> `test`
- `test/helpers` -> `app/helpers`
- `test/helpers` -> `test`
- `test/integration` -> `app/controllers`
- `test/integration` -> `app/models`
- `test/integration` -> `test`
- `test/jobs` -> `app/jobs`
- `test/jobs` -> `app/services/ai`
- `test/jobs` -> `test`
- `test/lib/platform/dsl/executors` -> `app/models`
- `test/lib/platform/dsl/executors` -> `app/services/ai/location_enricher`
- `test/lib/platform/dsl/executors` -> `app/services/ai`
- `test/lib/platform/dsl/executors` -> `lib/platform/dsl/executors`
- `test/lib/platform/dsl/executors` -> `lib/platform/services`
- `test/lib/platform/dsl/executors` -> `test`
- `test/lib/platform/dsl` -> `app/models`
- `test/lib/platform/dsl` -> `app/services/ai/location_enricher`
- `test/lib/platform/dsl` -> `app/services/ai`
- `test/lib/platform/dsl` -> `app/services/geo`
- `test/lib/platform/dsl` -> `app/services`
- `test/lib/platform/dsl` -> `lib/platform/dsl/executors`
- `test/lib/platform/dsl` -> `lib/platform/dsl`
- `test/lib/platform/dsl` -> `lib/platform/services`
- `test/lib/platform/dsl` -> `lib/platform`
- `test/lib/platform/dsl` -> `test`
- `test/lib/platform/services` -> `app/models`
- `test/lib/platform/services` -> `lib/platform/services`
- `test/lib/platform/services` -> `test`
- `test/lib/platform` -> `app/services/ai/location_enricher`
- `test/lib/platform` -> `lib/platform/dsl`
- `test/lib/platform` -> `lib/platform`
- `test/lib/platform` -> `lib`
- `test/lib/platform` -> `test`
- `test/lib` -> `lib`
- `test/lib` -> `test`
- `test/models` -> `app/models`
- `test/models` -> `app/services/mine_checker`
- `test/models` -> `app/services`
- `test/models` -> `test/support`
- `test/models` -> `test`
- `test/services/ai/location_enricher` -> `app/models`
- `test/services/ai/location_enricher` -> `app/services/ai/location_enricher`
- `test/services/ai/location_enricher` -> `app/services/ai`
- `test/services/ai/location_enricher` -> `test`
- `test/services/ai` -> `app/models`
- `test/services/ai` -> `app/services/ai/location_enricher`
- `test/services/ai` -> `app/services/ai`
- `test/services/ai` -> `app/services`
- `test/services/ai` -> `test`
- `test/services/geo` -> `app/services/geo`
- `test/services/geo` -> `test`
- `test/services/mine_checker` -> `app/models`
- `test/services/mine_checker` -> `app/services/mine_checker`
- `test/services/mine_checker` -> `test/support`
- `test/services/mine_checker` -> `test`
- `test/services` -> `app/models`
- `test/services` -> `app/services`
- `test/services` -> `test`
- `test/support` -> `app/services/mine_checker`
- `test/system` -> `app/models`
- `test/system` -> `test`
- `test` -> `app/models`
- `test` -> `config`
- `test` -> `test/support`

## Critical Modules

| Module | Fan-In | Fan-Out | Criticality |
|--------|--------|---------|-------------|
| `app/models` | 30 | 5 | high |
| `test` | 29 | 3 | high |
| `app/services/ai/location_enricher` | 13 | 4 | high |
| `app/services/ai` | 8 | 7 | high |
| `app/services` | 9 | 3 | high |
| `lib/platform/dsl/executors` | 3 | 8 | high |
| `app/controllers` | 4 | 6 | high |
| `test/lib/platform/dsl` | 0 | 10 | high |
| `lib/platform/dsl` | 4 | 5 | medium |
| `app/services/mine_checker` | 6 | 1 | medium |

## Risk Zones

- **Cyclic dependency detected (7 modules)** (confidence: 100%): The following modules form a dependency cycle: app/jobs -> app/models -> app/models/concerns -> app/services -> app/services/ai -> app/services/ai/location_enricher -> app/services/mine_checker -> app/jobs. This can cause initialization issues, make refactoring harder, and indicates tight coupling.
- **Cyclic dependency detected (2 modules)** (confidence: 100%): The following modules form a dependency cycle: lib/platform/dsl -> lib/platform/dsl/executors -> lib/platform/dsl. This can cause initialization issues, make refactoring harder, and indicates tight coupling.

## How to Add a Feature

General guidance:

1. Identify the appropriate module/package for the feature
2. Follow existing patterns in the codebase
3. Keep dependencies flowing in one direction
4. Add appropriate exports for cross-module usage
5. Wire the feature in the entry point

---

*Generated at 2026-08-05T10:00:30Z in 2.131711938s. 2782 facts, 58 insights.*
