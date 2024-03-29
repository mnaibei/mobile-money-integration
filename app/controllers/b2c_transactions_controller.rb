class B2cTransactionsController < ApplicationController
  require 'rest-client'
  include AccessTokens

  # b2c
  # This method is used to pay out to a phone number
  # Route: /b2c

  def b2c
    url = 'https://sandbox.safaricom.co.ke/mpesa/b2c/v3/paymentrequest'
    timestamp = Time.now.strftime('%Y%m%d%H%M%S').to_s
    business_short_code = ENV.fetch('MPESA_SHORTCODE', nil)
    password = Base64.strict_encode64("#{business_short_code}#{ENV.fetch('MPESA_PASSKEY', nil)}#{timestamp}")
    payload = {
      OriginatorConversationID: SecureRandom.uuid,
      InitiatorName: 'testapi',
      SecurityCredential: password,
      CommandID: 'BusinessPayment',
      Amount: params[:amount],
      PartyA: ENV.fetch('MPESA_SHORTCODE', nil),
      PartyB: params[:phoneNumber],
      Remarks: 'Payment for Codearn premium',
      QueueTimeOutURL: ENV.fetch('CALLBACK_URL', nil).to_s,
      ResultURL: ENV.fetch('CALLBACK_URL', nil).to_s,
      Occasion: 'Payment for Codearn premium',
      Timestamp: timestamp
    }.to_json

    headers = {
      Content_type: 'application/json',
      Authorization: "Bearer #{AccessTokens.get_access_token}"
    }

    RestClient::Request.new({
                              method: :post,
                              url:,
                              payload:,
                              headers:
                            }).execute do |response, _request|
      case response.code
      when 200
        transaction_details = JSON.parse(response.to_str)
        # Save transaction details to the database
        b2c_transaction = B2cTransaction.create!(
          transaction_id: transaction_details['ConversationID'],
          conversation_id: transaction_details['OriginatorConversationID'],
          response_code: transaction_details['ResponseCode'],
          response_description: transaction_details['ResponseDescription'],
          phoneNumber: params[:phoneNumber],
          amount: params[:amount]
        )
        render json: { success: true, b2c_transaction: }
      else
        render json: { error: "Invalid response #{response.to_str} received." }
      end
    end
  end
end
