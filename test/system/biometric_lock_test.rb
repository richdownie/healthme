require "application_system_test_case"

class BiometricLockTest < ApplicationSystemTestCase
  setup do
    @user = users(:alice)
  end

  test "biometric toggle reflects stored setting on connect" do
    system_sign_in(@user)
    visit profile_path
    assert_selector "h1", text: "Your Profile"

    inject_capacitor_mock(biometric_enabled: true)
    trigger_controller_methods

    assert_biometric_section_visible
    assert_biometric_toggle_checked
  end

  test "biometric toggle persists after Turbo navigation" do
    system_sign_in(@user)
    visit profile_path
    assert_selector "h1", text: "Your Profile"

    inject_capacitor_mock(biometric_enabled: true)
    trigger_controller_methods

    assert_biometric_toggle_checked

    # Navigate away via Turbo and back — mock persists in window
    click_link "Home"
    assert_selector "h1", text: "HealthMe", wait: 3

    click_link "Profile"
    assert_selector "h1", text: "Your Profile", wait: 3

    # After Turbo navigation, controller.connect() runs with mock in window.
    # With the fix, loadSetting() is always called, so toggle should be checked.
    sleep 0.5
    assert_biometric_section_visible
    assert_biometric_toggle_checked
  end

  test "biometric toggle shows OFF when stored setting is false" do
    system_sign_in(@user)
    visit profile_path

    inject_capacitor_mock(biometric_enabled: false)
    trigger_controller_methods

    assert_biometric_section_visible
    assert_biometric_toggle_unchecked
  end

  private

  def system_sign_in(user)
    visit new_session_path
    assert_selector "h1", text: "HealthMe", wait: 5
    page.execute_script(<<~JS)
      fetch('#{session_path}', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector("[data-auth-target='csrfToken']").value
        },
        body: JSON.stringify({test_user_id: #{user.id}})
      }).then(r => r.json()).then(d => {
        if (d.success) window.Turbo.visit(d.redirect_to);
      })
    JS
    assert_current_path root_path, wait: 5
  end

  def inject_capacitor_mock(biometric_enabled: false)
    page.execute_script(<<~JS)
      window._mockStorage = { biometric_enabled: "#{biometric_enabled}" };
      window._biometricUnlocked = true;
      window.Capacitor = {
        isNativePlatform: function() { return true; },
        Plugins: {
          SecureStoragePlugin: {
            get: function(opts) {
              var val = window._mockStorage[opts.key];
              if (val !== undefined) return Promise.resolve({ value: val });
              return Promise.reject(new Error("Key not found"));
            },
            set: function(opts) {
              window._mockStorage[opts.key] = opts.value;
              return Promise.resolve();
            }
          },
          BiometricAuth: {
            authenticate: function() { return Promise.resolve({}); },
            isAvailable: function() { return Promise.resolve({ available: true }); }
          },
          App: {
            addListener: function() { return {}; }
          }
        }
      };
    JS
  end

  # Re-trigger controller logic since the mock was injected after initial connect
  def trigger_controller_methods
    page.execute_script(<<~JS)
      var ctrl = window.Stimulus.getControllerForElementAndIdentifier(document.body, 'biometric-lock');
      if (ctrl) {
        ctrl.showToggleSection();
        ctrl.loadSetting();
      }
    JS
    sleep 0.5
  end

  # The toggle input is visually hidden (opacity:0) for the toggle switch CSS,
  # so we check state via JS rather than Capybara visibility.
  def assert_biometric_section_visible
    visible = page.evaluate_script(<<~JS)
      (function() {
        var section = document.querySelector("[data-biometric-lock-target='toggleSection']");
        return section && section.style.display !== 'none';
      })()
    JS
    assert visible, "Biometric toggle section should be visible"
  end

  def assert_biometric_toggle_checked
    checked = page.evaluate_script(<<~JS)
      (function() {
        var toggle = document.querySelector("[data-biometric-lock-target='toggle']");
        return toggle && toggle.checked;
      })()
    JS
    assert checked, "Biometric toggle should be checked (ON)"
  end

  def assert_biometric_toggle_unchecked
    unchecked = page.evaluate_script(<<~JS)
      (function() {
        var toggle = document.querySelector("[data-biometric-lock-target='toggle']");
        return toggle && !toggle.checked;
      })()
    JS
    assert unchecked, "Biometric toggle should be unchecked (OFF)"
  end
end
