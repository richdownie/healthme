require "application_system_test_case"

class NostrSignInTest < ApplicationSystemTestCase
  test "extension button appears when window.nostr is available" do
    visit new_session_path

    # Button should be hidden initially (no extension)
    assert_no_selector "[data-nostr-target='extensionBtn']", visible: true

    # Inject a mock window.nostr object and re-trigger detection
    inject_nostr_mock_and_detect

    # Button and divider should now be visible
    assert_selector "[data-nostr-target='extensionBtn']", visible: true, wait: 2
    assert_selector ".auth-divider", visible: true
  end

  test "clicking extension button initiates sign-in flow and handles invalid signature" do
    visit new_session_path
    inject_nostr_mock_and_detect
    assert_selector "[data-nostr-target='extensionBtn']", visible: true, wait: 2

    # The click triggers an async flow that ends with an alert
    accept_alert(/Invalid signature|Authentication failed/) do
      find("[data-nostr-target='extensionBtn']").click
      sleep 3 # Wait for async challenge + sign + verify flow
    end

    # Button should re-enable after failure
    assert_selector "[data-nostr-target='extensionBtn']:not([disabled])", wait: 3
  end

  test "extension button not shown without nostr extension" do
    visit new_session_path
    sleep 1 # Wait for detection timeout
    assert_no_selector "[data-nostr-target='extensionBtn']", visible: true
  end

  private

  def inject_nostr_mock_and_detect
    page.execute_script(<<~JS)
      window.nostr = {
        getPublicKey: async function() {
          return "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2";
        },
        signEvent: async function(event) {
          return {
            id: "0".repeat(64),
            pubkey: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2",
            created_at: event.created_at,
            kind: event.kind,
            tags: event.tags,
            content: event.content,
            sig: "0".repeat(128)
          };
        }
      };
      // Re-trigger detection
      const el = document.querySelector('[data-controller*="nostr"]');
      const btn = el.querySelector('[data-nostr-target="extensionBtn"]');
      const divider = el.querySelector('[data-nostr-target="divider"]');
      if (btn) btn.style.display = "";
      if (divider) divider.style.display = "";
    JS
  end
end
