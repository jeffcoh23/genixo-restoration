class StandardizeTimezoneFormat < ActiveRecord::Migration[8.0]
  def up
    # Convert IANA timezone identifiers to Rails timezone names so the
    # Settings dropdown (which uses ActiveSupport::TimeZone#name) can
    # pre-select the user's current value.
    {
      "America/New_York" => "Eastern Time (US & Canada)",
      "America/Chicago" => "Central Time (US & Canada)",
      "America/Denver" => "Mountain Time (US & Canada)",
      "America/Los_Angeles" => "Pacific Time (US & Canada)"
    }.each do |iana, rails_name|
      execute "UPDATE users SET timezone = '#{rails_name}' WHERE timezone = '#{iana}'"
    end

    change_column_default :users, :timezone, "Central Time (US & Canada)"
  end

  def down
    change_column_default :users, :timezone, "America/Chicago"
  end
end
