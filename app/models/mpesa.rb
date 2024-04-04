class Mpesa < ApplicationRecord
    #ensure the presence of the following attributes before saving to the database
    validates :phoneNumber, :amount, :checkoutRequestID, :merchantRequestID, presence: true
end
