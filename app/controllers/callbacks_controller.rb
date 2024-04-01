class CallbacksController < ApplicationController
  require 'rest-client'
  include AccessTokens

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
      Authorization: "Bearer #{AccessTokens.get_access_token}"
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
  # Updates db column with state of transaction(success/fail)
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

  private

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

    b2c_transaction = B2cTransaction.find_by(transaction_id:)

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
