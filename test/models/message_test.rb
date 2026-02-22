require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)

    @manager = User.create!(
      organization: @mitigation,
      user_type: User::MANAGER,
      email_address: "manager@example.com",
      first_name: "Mia",
      last_name: "Manager",
      password: "password123"
    )

    @incident = Incident.create!(
      property: @property,
      created_by_user: @manager,
      status: "active",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Water intrusion"
    )
  end

  test "is valid with body text" do
    message = Message.new(incident: @incident, user: @manager, body: "Crew on site.")
    assert message.valid?
  end

  test "is valid with attachment and blank body" do
    message = Message.new(incident: @incident, user: @manager, body: "")
    attachment = message.attachments.build(uploaded_by_user: @manager, category: "general")
    attachment.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_photo.jpg")),
      filename: "test_photo.jpg",
      content_type: "image/jpeg"
    )

    assert message.valid?
    assert message.save
    assert_equal 1, message.attachments.count
  end

  test "is invalid without body or attachments" do
    message = Message.new(incident: @incident, user: @manager, body: "   ")
    assert_not message.valid?
    assert_includes message.errors[:body], "can't be blank"
  end
end
