require 'swagger_helper'

RSpec.describe 'b2c_transactions', type: :request do

  path '/b2c' do

    post('b2c b2c_transaction') do
      response(200, 'successful') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
