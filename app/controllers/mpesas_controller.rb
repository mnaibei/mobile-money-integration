class MpesasController < ApplicationController
   
    require 'rest-client'

    # stkpush
    # This method is used to initiate a payment request to the customer's phone
    # Route: /pay
    def stkpush
        phoneNumber = params[:phoneNumber]
        amount = params[:amount]
        url = "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"
        timestamp = "#{Time.now.strftime "%Y%m%d%H%M%S"}"
        business_short_code = ENV["MPESA_SHORTCODE"]
        password = Base64.strict_encode64("#{business_short_code}#{ENV["MPESA_PASSKEY"]}#{timestamp}")
        payload = {
          'BusinessShortCode': business_short_code,
          'Password': password,
          'Timestamp': timestamp,
          'TransactionType': "CustomerPayBillOnline",
          'Amount': amount,
          'PartyA': phoneNumber,
          'PartyB': business_short_code,
          'PhoneNumber': phoneNumber,
          'CallBackURL': "#{ENV["CALLBACK_URL"]}",
          'AccountReference': 'Codearn',
          'TransactionDesc': "Payment for Codearn premium"
        }.to_json
      
        headers = {
          Content_type: 'application/json',
          Authorization: "Bearer #{get_access_token}"
        }
      
        response = RestClient::Request.new({
          method: :post,
          url: url,
          payload: payload,
          headers: headers
        }).execute do |response, request|
          case response.code
          when 500, 401, 400
            render json: { error: JSON.parse(response.to_str) }
            return
          when 200
            # Save transaction details to the database
            transaction_details = JSON.parse(response.to_str)
            mpesa = Mpesa.create!(
              phoneNumber: phoneNumber,
              amount: amount,
              checkoutRequestID: transaction_details['CheckoutRequestID'],
              merchantRequestID: transaction_details['MerchantRequestID'],
              mpesaReceiptNumber: transaction_details['MpesaReceiptNumber']
            )
            render json: { success: true, mpesa: mpesa }
            return
          else
            render json: { error: "Invalid response #{response.to_str} received." }
            return
          end
        end
      end


    # stkquery
    # This method is used to query the status of a payment request
    # Route: /payment_query

    def stkquery
        url = "https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query"
        timestamp = "#{Time.now.strftime "%Y%m%d%H%M%S"}"
        business_short_code = ENV["MPESA_SHORTCODE"]
        password = Base64.strict_encode64("#{business_short_code}#{ENV["MPESA_PASSKEY"]}#{timestamp}")
        payload = {
        'BusinessShortCode': business_short_code,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': params[:checkoutRequestID]
        }.to_json

        headers = {
        Content_type: 'application/json',
        Authorization: "Bearer #{ get_access_token }"
        }

        response = RestClient::Request.new({
        method: :post,
        url: url,
        payload: payload,
        headers: headers
        }).execute do |response, request|
        case response.code
        when 500
        [ :error, JSON.parse(response.to_str) ]
        render json: response
        when 400
        [ :error, JSON.parse(response.to_str) ]
        when 200
        [ :success, JSON.parse(response.to_str) ]
        else
        fail "Invalid response #{response.to_str} received."
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
        rescue JSON::ParserError => e
          # If JSON parsing fails, respond with an error status
          render json: { error: 'Failed to parse JSON data' }, status: :bad_request
          return
        end
    
        # Extract relevant information from the notification data
        checkout_request_id = notification_data['mpesa']['checkoutRequestID'] # Use the correct key to access checkoutRequestID
    
        # Find the corresponding transaction record in your database based on checkoutRequestID
        mpesa_transaction = Mpesa.find_by(checkoutRequestID: checkout_request_id)
    
        if mpesa_transaction
          # Update the transaction record based on the result code
          result_code = notification_data['success'] ? '0' : '1' # Assuming 'success' indicates success or failure
          case result_code
          when '0' # Success
            mpesa_transaction.update(status: 'completed')
          else
            mpesa_transaction.update(status: 'failed')
          end
    
          # Respond with a success status
          render json: { success: true }
        else
          # If transaction not found, respond with an error status
          render json: { error: 'Transaction not found' }, status: :not_found
        end
      end

    # b2c
    # This method is used to pay out to a phone number
    # Route: /b2c

    def b2c
        url = "https://sandbox.safaricom.co.ke/mpesa/b2c/v3/paymentrequest"
        timestamp = "#{Time.now.strftime "%Y%m%d%H%M%S"}"
        business_short_code = ENV["MPESA_SHORTCODE"]
        password = Base64.strict_encode64("#{business_short_code}#{ENV["MPESA_PASSKEY"]}#{timestamp}")
        payload = {
            "OriginatorConversationID": SecureRandom.uuid,
            'InitiatorName': "testapi",
            'SecurityCredential': password,
            'CommandID': "BusinessPayment",
            'Amount': params[:amount],
            'PartyA': ENV["MPESA_SHORTCODE"],
            'PartyB': params[:phoneNumber],
            'Remarks': "Payment for Codearn premium",
            'QueueTimeOutURL': "#{ENV["CALLBACK_URL"]}",
            'ResultURL': "#{ENV["CALLBACK_URL"]}",
            'Occasion': "Payment for Codearn premium"
        }.to_json

        headers = {
            Content_type: 'application/json',
            Authorization: "Bearer #{ get_access_token }"
        }

        response = RestClient::Request.new({
            method: :post,
            url: url,
            payload: payload,
            headers: headers
        }).execute do |response, request|
            case response.code
            when 500
            [ :error, JSON.parse(response.to_str) ]
            when 400
            [ :error, JSON.parse(response.to_str) ]
            when 200
            [ :success, JSON.parse(response.to_str) ]
            else
            fail "Invalid response #{response.to_str} received."
            end
        end
        render json: response
    end

    private

    def generate_access_token_request
        @url = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
        @consumer_key = ENV['MPESA_CONSUMER_KEY']
        @consumer_secret = ENV['MPESA_CONSUMER_SECRET']
        @userpass = Base64::strict_encode64("#{@consumer_key}:#{@consumer_secret}")
        headers = {
            Authorization: "Bearer #{@userpass}"
        }
        res = RestClient::Request.execute( url: @url, method: :get, headers: {
            Authorization: "Basic #{@userpass}"
        })
        res
    end

    def get_access_token
        res = generate_access_token_request()
        attempts = 0
        while res.code != 200 && attempts < 5
            res = generate_access_token_request()
            attempts += 1
        end
        puts "Attempts: #{attempts}"
        if res.code != 200
            raise MpesaError('Unable to generate access token')
        end
        body = JSON.parse(res, { symbolize_names: true })
        token = body[:access_token]
        AccessToken.destroy_all()
        AccessToken.create!(token: token)
        token
    end




end
