class Property < ApplicationRecord
  belongs_to :property_management_org, class_name: "Organization"
  belongs_to :mitigation_org, class_name: "Organization"

  has_many :incidents, dependent: :destroy
  has_many :property_assignments, dependent: :destroy
  has_many :assigned_users, through: :property_assignments, source: :user

  validates :name, presence: true
end
