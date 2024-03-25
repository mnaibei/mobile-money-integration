class MpesasController < ApplicationController
  require 'rest-client'

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
      Authorization: "Bearer #{get_access_token}"
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

  # stkquery
  # This method is used to query the status of a payment request
  # Route: /payment_query
  def stkquery
    url = 'https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query'
    timestamp = Time.now.strftime('%Y%m%d%H%M%S').to_s
    business_short_code = ENV.fetch('MPESA_SHORTCODE', nil)
    password = Base64.strict_encode64("#{business_short_code}#{ENV.fetch('MPESA_PASSKEY', nil)}#{timestamp}")
    payload = {
      BusinessShortCode: business_short_code,
      Password: password,
      Timestamp: timestamp,
      CheckoutRequestID: params[:checkoutRequestID]
    }.to_json

    headers = {
      Content_type: 'application/json',
      Authorization: "Bearer #{get_access_token}"
    }

    response = RestClient::Request.new({
                                         method: :post,
                                         url:,
                                         payload:,
                                         headers:
                                       }).execute do |response, _request|
      case response.code
      when 500
        render json: response
      when 400
        [:error, JSON.parse(response.to_str)]
      when 200
        [:success, JSON.parse(response.to_str)]
      else
        raise "Invalid response #{response.to_str} received."
      end
    end
    render json: response
  end

# Endpoint to handle Mpesa's callback notifications
def mpesa_callback
    begin
      # Parse the notification data
      notification_data = JSON.parse(request.body.read)
      puts "Notification Data: #{notification_data}"
    rescue JSON::ParserError
      # If JSON parsing fails, respond with an error status
      render json: { error: 'Failed to parse JSON data' }, status: :bad_request
      return
    end
  
    if notification_data.key?('mpesa')
      # This is an mpesa transaction
      handle_mpesa_transaction(notification_data)
    elsif notification_data.key?('b2c_transaction')
      # This is a b2c transaction
      handle_b2c_transaction(notification_data)
    else
      # If neither mpesa nor b2c transaction data is found, respond with an error status
      render json: { error: 'Invalid transaction data' }, status: :unprocessable_entity
    end
  end

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
      Authorization: "Bearer #{get_access_token}"
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

  private

  def generate_access_token_request
    @url = 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'
    @consumer_key = ENV.fetch('MPESA_CONSUMER_KEY', nil)
    @consumer_secret = ENV.fetch('MPESA_CONSUMER_SECRET', nil)
    @userpass = Base64.strict_encode64("#{@consumer_key}:#{@consumer_secret}")
    RestClient::Request.execute(url: @url, method: :get, headers: {
                                  Authorization: "Basic #{@userpass}"
                                })
  end

  def get_access_token
    res = generate_access_token_request
    attempts = 0
    while res.code != 200 && attempts < 5
      res = generate_access_token_request
      attempts += 1
    end
    puts "Attempts: #{attempts}"
    raise MpesaError('Unable to generate access token') if res.code != 200

    body = JSON.parse(res, { symbolize_names: true })
    token = body[:access_token]
    AccessToken.destroy_all
    AccessToken.create!(token:)
    token
  end

  # Handle mpesa transaction
def handle_mpesa_transaction(notification_data)
    checkout_request_id = notification_data['mpesa']['checkoutRequestID']
    result_code = notification_data['success'] ? '0' : '1'
  
    mpesa_transaction = Mpesa.find_by(checkoutRequestID: checkout_request_id)
  
    if mpesa_transaction
      case result_code
      when '0'
        mpesa_transaction.update(status: 'completed')
      else
        mpesa_transaction.update(status: 'failed')
      end
      render json: { success: true }
    else
      render json: { error: 'Mpesa Transaction not found' }, status: :not_found
    end
  end
  
  # Handle b2c transaction
  def handle_b2c_transaction(notification_data)
    transaction_id = notification_data['b2c_transaction']['transaction_id']
    result_code = notification_data['success'] ? '0' : '1'
  
    b2c_transaction = B2cTransaction.find_by(transaction_id: transaction_id)
  
    if b2c_transaction
      case result_code
      when '0'
        b2c_transaction.update(status: 'completed')
      else
        b2c_transaction.update(status: 'failed')
      end
      render json: { success: true }
    else
      render json: { error: 'B2c Transaction not found' }, status: :not_found
    end
  end
end
