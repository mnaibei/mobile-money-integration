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
        when 500
        [ :error, JSON.parse(response.to_str) ]
        print response
        when 401
        [ :error, JSON.parse(response.to_str) ]
        print response
        when 400
        [ :error, JSON.parse(response.to_str) ]
        print response
        when 200
        [ :success, JSON.parse(response.to_str) ]
        print response
        else
        fail "Invalid response #{response.to_str} received."
        end
        end
        render json: response
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
