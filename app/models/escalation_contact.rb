class EscalationContact < ApplicationRecord
  belongs_to :on_call_configuration
  belongs_to :user

  validates :position, presence: true, uniqueness: { scope: :on_call_configuration_id }
end
