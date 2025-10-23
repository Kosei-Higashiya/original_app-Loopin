# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo-rails@8.0.16/+esm"
pin "@hotwired/stimulus", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm"

# Pin Chart.js from CDN - using ESM version
pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm"

# Pin controllers
pin "controllers/index", to: "controllers/index.js"
pin "controllers/application", to: "controllers/application.js"
pin "controllers/hello_controller", to: "controllers/hello_controller.js"
pin "controllers/chart_controller", to: "controllers/chart_controller.js"
