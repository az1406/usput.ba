# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "leaflet", to: "https://ga.jspm.io/npm:leaflet@1.9.4/dist/leaflet-src.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/services", under: "services"
