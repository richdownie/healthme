# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "chart.js/auto", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.8/dist/chart.umd.js"

# Nostr-style keypair auth crypto libraries (vendored bundles for WKWebView compatibility)
pin "@noble/curves/secp256k1", to: "noble-curves-secp256k1.js"
pin "@noble/hashes/sha256", to: "noble-hashes-sha256.js"
pin "@noble/hashes/utils", to: "noble-hashes-utils.js"
pin "@scure/base", to: "scure-base.js"
