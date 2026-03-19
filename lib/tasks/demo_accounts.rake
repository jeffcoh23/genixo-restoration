# frozen_string_literal: true

# Creates / resets demo accounts for Apple App Store review.
# Run:   bin/rails demo:setup
# Safe to run multiple times — finds or creates, resets passwords.

namespace :demo do
  desc "Create or reset demo accounts for Apple App Store review"
  task setup: :environment do
    PASSWORD = "GenixoDemo2026!"

    # Ensure the mitigation org exists
    org = Organization.find_by(organization_type: "mitigation")
    abort "No mitigation organization found. Run db:seed first." unless org

    demo_user = find_or_reset!(
      org: org,
      email: "demo@genixorestoration.com",
      first_name: "Demo",
      last_name: "Reviewer",
      user_type: User::MANAGER,
      phone: "210-555-0199"
    )

    puts ""
    puts "=== Apple Review Demo Account ==="
    puts "Email:    #{demo_user.email_address}"
    puts "Password: #{PASSWORD}"
    puts "Role:     #{demo_user.display_role} (#{org.name})"
    puts ""
    puts "Copy these into App Store Connect review notes."
    puts "================================="
  end

  def find_or_reset!(org:, email:, first_name:, last_name:, user_type:, phone:)
    user = User.find_or_initialize_by(email_address: email)
    is_new = user.new_record?
    user.assign_attributes(
      organization: org,
      first_name: first_name,
      last_name: last_name,
      user_type: user_type,
      phone: phone,
      password: PASSWORD,
      timezone: "Central Time (US & Canada)",
      active: true
    )
    user.permissions = Permissions.defaults_for(user_type) if is_new
    user.save!
    puts "  #{is_new ? 'Created' : 'Reset'}: #{email} (#{user_type})"
    user
  end
end
