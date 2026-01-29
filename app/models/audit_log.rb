class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  class << self
    # @param user [User, nil]
    # @param action [String] e.g. "transaction.created", "invoice.reconciled"
    # @param auditable [ApplicationRecord]
    # @param metadata [Hash] optional extra data (stored as JSON string)
    def log(user, action, auditable, metadata = {})
      create!(
        user_id: user&.id,
        action: action.to_s,
        auditable_type: auditable.class.name,
        auditable_id: auditable.id,
        metadata: metadata.presence && metadata.to_json
      )
    end
  end
end
