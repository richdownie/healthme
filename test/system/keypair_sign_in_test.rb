require "application_system_test_case"

class KeypairSignInTest < ApplicationSystemTestCase
  # Test keypair (secp256k1/Schnorr) generated for E2E testing
  SECRET_HEX = "69edcb2ef73c95c28c78ed88b1d9445a41406913b980217b7e629be7f2d5d05b"
  PUBKEY_HEX = "055555476f193e47dbf4eeac5c1762a83fe6fcc0730d4fd86920b86ec6639cfa"

  test "sign in with existing hex key via 'I Have a Key' tab" do
    visit new_session_path
    pause_if_headed

    # Switch to the "I Have a Key" tab
    click_on "I Have a Key"
    pause_if_headed

    # Enter the secret key hex
    find("[data-keypair-target='nsecInput']").set(SECRET_HEX)

    # Wait for derived public key to appear (confirms JS keypair derivation works)
    assert_selector "[data-keypair-target='derivedDisplay']", visible: true, wait: 3
    pause_if_headed

    # Click Sign In — triggers challenge → sign → verify flow
    click_on "Sign In"

    # Should land on the activities dashboard
    assert_text "Your daily health tracker", wait: 10
    pause_if_headed

    # Verify the user was created with the correct pubkey
    user = User.find_by(pubkey_hex: PUBKEY_HEX)
    assert user, "Expected a user to be created with pubkey #{PUBKEY_HEX}"
  end

  test "sign in with generated keypair via 'New Keypair' tab" do
    visit new_session_path
    pause_if_headed

    # Click Generate Keypair
    click_on "Generate Keypair"

    # npub and nsec fields should appear
    assert_selector "[data-keypair-target='npubField']", visible: true, wait: 3
    assert_selector "[data-keypair-target='nsecField']", visible: true
    pause_if_headed

    # Click Sign In
    within("[data-keypair-target='generatePanel']") do
      click_on "Sign In"
    end

    # Should land on the activities dashboard
    assert_text "Your daily health tracker", wait: 10
    pause_if_headed
  end

  test "sign in persists session across page navigation" do
    visit new_session_path

    click_on "I Have a Key"
    find("[data-keypair-target='nsecInput']").set(SECRET_HEX)
    assert_selector "[data-keypair-target='derivedDisplay']", visible: true, wait: 3
    click_on "Sign In"
    assert_text "Your daily health tracker", wait: 10
    pause_if_headed

    # Navigate away and back — session should persist
    visit root_path
    assert_text "Your daily health tracker"
    assert_no_text "Sign in with your keypair"
    pause_if_headed
  end

  private

  def pause_if_headed
    sleep 2 if ENV["HEADLESS"] == "false"
  end
end
