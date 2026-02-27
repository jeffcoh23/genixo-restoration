require "test_helper"

class UnreadCacheServiceTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")

    @incident = Incident.create!(property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Test")
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)

    # Use memory store for cache tests (test env defaults to null_store)
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "has_unread? returns false when no messages or activity" do
    assert_not UnreadCacheService.has_unread?(@manager)
  end

  test "has_unread? returns true when unread messages exist" do
    Message.create!(incident: @incident, user: @tech, body: "Hello")
    Rails.cache.clear

    assert UnreadCacheService.has_unread?(@manager)
  end

  test "has_unread? returns false for message sender" do
    Message.create!(incident: @incident, user: @manager, body: "My own message")
    Rails.cache.clear

    assert_not UnreadCacheService.has_unread?(@manager)
  end

  test "has_unread? caches result and expire clears it" do
    # First call computes and caches false
    assert_not UnreadCacheService.has_unread?(@manager)
    assert Rails.cache.exist?("has_unread:#{@manager.id}")

    # Expire clears the cache key
    UnreadCacheService.expire_for_user(@manager)
    assert_not Rails.cache.exist?("has_unread:#{@manager.id}")

    # After creating a message, recomputed result is true
    Message.create!(incident: @incident, user: @tech, body: "Hello")
    Rails.cache.clear
    assert UnreadCacheService.has_unread?(@manager)
  end

  test "expire_for_incident clears cache for visible users" do
    UnreadCacheService.has_unread?(@manager)
    assert Rails.cache.exist?("has_unread:#{@manager.id}")

    UnreadCacheService.expire_for_incident(@incident, exclude_user: @tech)
    assert_not Rails.cache.exist?("has_unread:#{@manager.id}")
  end

  test "expire_for_incident excludes the acting user" do
    UnreadCacheService.has_unread?(@manager)
    UnreadCacheService.has_unread?(@tech)

    UnreadCacheService.expire_for_incident(@incident, exclude_user: @tech)
    assert Rails.cache.exist?("has_unread:#{@tech.id}")
    assert_not Rails.cache.exist?("has_unread:#{@manager.id}")
  end

  test "expire_for_user clears both cache keys" do
    UnreadCacheService.has_unread?(@manager)
    UnreadCacheService.unread_counts(@manager)

    assert Rails.cache.exist?("has_unread:#{@manager.id}")
    assert Rails.cache.exist?("unread_counts:#{@manager.id}")

    UnreadCacheService.expire_for_user(@manager)

    assert_not Rails.cache.exist?("has_unread:#{@manager.id}")
    assert_not Rails.cache.exist?("unread_counts:#{@manager.id}")
  end

  test "message creation expires cache via model callback" do
    UnreadCacheService.has_unread?(@manager)
    assert Rails.cache.exist?("has_unread:#{@manager.id}")

    Message.create!(incident: @incident, user: @tech, body: "Triggers callback")

    assert_not Rails.cache.exist?("has_unread:#{@manager.id}")
  end

  test "incident_read_state save expires cache via model callback" do
    Message.create!(incident: @incident, user: @tech, body: "Hello")
    Rails.cache.clear
    UnreadCacheService.has_unread?(@manager)
    assert Rails.cache.exist?("has_unread:#{@manager.id}")

    IncidentReadState.create!(incident: @incident, user: @manager, last_message_read_at: Time.current)

    assert_not Rails.cache.exist?("has_unread:#{@manager.id}")
  end
end
