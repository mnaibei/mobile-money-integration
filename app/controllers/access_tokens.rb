module AccessTokens
  require 'rest-client'

  def self.generate_access_token_request
    @url = 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'
    @consumer_key = ENV.fetch('MPESA_CONSUMER_KEY', nil)
    @consumer_secret = ENV.fetch('MPESA_CONSUMER_SECRET', nil)
    @userpass = Base64.strict_encode64("#{@consumer_key}:#{@consumer_secret}")
    RestClient::Request.execute(url: @url, method: :get, headers: {
                                  Authorization: "Basic #{@userpass}"
                                })
  end

  def self.get_access_token
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
end
