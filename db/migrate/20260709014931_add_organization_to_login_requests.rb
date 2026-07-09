class AddOrganizationToLoginRequests < ActiveRecord::Migration[8.0]
  def change
    # Nullable at the DB level so any pre-existing free-text requests survive;
    # new requests require it via a model validation (on: :create).
    add_reference :login_requests, :organization, null: true, foreign_key: true
  end
end
