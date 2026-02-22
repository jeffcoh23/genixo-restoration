require "test_helper"

class AttachmentTest < ActiveSupport::TestCase
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

  test "is valid with allowed category and attached file" do
    attachment = Attachment.new(
      attachable: @incident,
      uploaded_by_user: @manager,
      category: "photo",
      description: "Bedroom wall moisture map"
    )
    File.open(Rails.root.join("test/fixtures/files/test_photo.jpg"), "rb") do |io|
      attachment.file.attach(io: io, filename: "test_photo.jpg", content_type: "image/jpeg")
    end

    assert attachment.valid?
  end

  test "is invalid with unsupported category" do
    attachment = Attachment.new(
      attachable: @incident,
      uploaded_by_user: @manager,
      category: "unsupported_category"
    )

    assert_not attachment.valid?
    assert_includes attachment.errors[:category], "is not included in the list"
  end

  test "requires category" do
    attachment = Attachment.new(
      attachable: @incident,
      uploaded_by_user: @manager,
      category: nil
    )

    assert_not attachment.valid?
    assert_includes attachment.errors[:category], "can't be blank"
  end
end
