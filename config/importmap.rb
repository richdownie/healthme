# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Nostr-style keypair auth crypto libraries
pin "@noble/curves/secp256k1", to: "https://esm.sh/@noble/curves@1.8.1/secp256k1"
pin "@noble/hashes/sha256", to: "https://esm.sh/@noble/hashes@1.7.1/sha256.js"
pin "@noble/hashes/utils", to: "https://esm.sh/@noble/hashes@1.7.1/utils.js"
pin "@scure/base", to: "https://esm.sh/@scure/base@1.2.4"
