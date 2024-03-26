class MpesasController < ApplicationController
  require 'rest-client'
  include AccessTokens

  # stkpush
  # This method is used to initiate a payment request to the customer's phone
  # Route: /pay
  def stkpush
    phoneNumber = params[:phoneNumber]
    amount = params[:amount]
    url = 'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest'
    timestamp = Time.now.strftime('%Y%m%d%H%M%S').to_s
    business_short_code = ENV.fetch('MPESA_SHORTCODE', nil)
    password = Base64.strict_encode64("#{business_short_code}#{ENV.fetch('MPESA_PASSKEY', nil)}#{timestamp}")
    payload = {
      BusinessShortCode: business_short_code,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: amount,
      PartyA: phoneNumber,
      PartyB: business_short_code,
      PhoneNumber: phoneNumber,
      CallBackURL: ENV.fetch('CALLBACK_URL', nil).to_s,
      AccountReference: 'Codearn',
      TransactionDesc: 'Payment for Codearn premium'
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
      when 500, 401, 400
        render json: { error: JSON.parse(response.to_str) }
      when 200
        # Save transaction details to the database
        transaction_details = JSON.parse(response.to_str)
        mpesa = Mpesa.create!(
          phoneNumber:,
          amount:,
          checkoutRequestID: transaction_details['CheckoutRequestID'],
          merchantRequestID: transaction_details['MerchantRequestID'],
          mpesaReceiptNumber: transaction_details['MpesaReceiptNumber']
        )
        render json: { success: true, mpesa: }
      else
        render json: { error: "Invalid response #{response.to_str} received." }
      end
      return
    end
  end
end
