class Organization < ApplicationRecord
  TYPES = %w[mitigation property_management].freeze

  has_many :users, dependent: :destroy

  # Properties where this org is the PM owner
  has_many :owned_properties, class_name: "Property", foreign_key: :property_management_org_id, dependent: :destroy, inverse_of: :property_management_org

  # Properties where this org is the mitigation servicer
  has_many :serviced_properties, class_name: "Property", foreign_key: :mitigation_org_id, dependent: :destroy, inverse_of: :mitigation_org

  # Mitigation org only
  has_many :equipment_types, dependent: :destroy
  has_one :on_call_configuration, dependent: :destroy
  has_many :invitations, dependent: :destroy

  validates :name, presence: true
  validates :organization_type, presence: true, inclusion: { in: TYPES }

  def mitigation?
    organization_type == "mitigation"
  end

  def property_management?
    organization_type == "property_management"
  end
end
