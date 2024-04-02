class B2cTransaction < ApplicationRecord
    validates :phoneNumber, :amount, :transaction_id, :conversation_id, :response_code, :response_description, :status, presence: true
end
