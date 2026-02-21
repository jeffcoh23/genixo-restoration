require "test_helper"

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(app, browser_type: :chromium, headless: true)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :playwright

  # System tests must not run in parallel — Capybara binds a single server port
  parallelize(workers: 1)

  private

  def login_as(user, password: "password123")
    visit "/login"
    fill_in "Email", with: user.email_address
    fill_in "Password", with: password
    click_button "Sign In"
    assert_text user.full_name  # Wait for login redirect to complete
  end
end
