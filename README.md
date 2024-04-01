# Mpesa API Integration with Ruby on Rails

This project demonstrates the integration of Mpesa API with a Ruby on Rails application. It provides functionalities for initiating payment requests, querying payment status, and making payments to phone numbers.

## Features

- **stkpush**: Initiate a payment request to the customer's phone using STK Push.
- **stkquery**: Query the status of a payment request.
- **b2c**: Pay out to a phone number using Business to Customer payment.

## Setup

1. Clone the repository:

   ```bash
   git clone <repository_url>
   ```

2. Install dependencies:

   ```bash
   bundle install
   ```

3. Set up environment variables:

   - `MPESA_SHORTCODE`: Your Mpesa short code.
   - `MPESA_PASSKEY`: Your Mpesa passkey.
   - `MPESA_CONSUMER_KEY`: Your Mpesa consumer key.
   - `MPESA_CONSUMER_SECRET`: Your Mpesa consumer secret.
   - `CALLBACK_URL`: URL where Mpesa callbacks will be received.

4. Run the Rails server:

   ```bash
   rails s
   ```

5. Go to this link to view api docs:
   ```http
   https://example.com/api-docs
   ```

## Usage

### stkpush

Initiate a payment request to the customer's phone.

```ruby
POST /pay
Params:
- phoneNumber: "Customer's phone number"
- amount: "Amount to be paid"
- Example response = {
    "success": true,
    "mpesa": {
        "id": 5,
        "phoneNumber": "",
        "amount": "1",
        "checkoutRequestID": "ws_CO_01042024164530692708374149",
        "merchantRequestID": "6e86-45dd-91ac-fd5d4178ab521642874",
        "mpesaReceiptNumber": null,
        "created_at": "2024-04-01T13:45:34.947Z",
        "updated_at": "2024-04-01T13:45:34.947Z",
        "status": null
    }
}
```

### stkquery

Query the status of a payment request.

```ruby
POST /payment_query
Params:
- checkoutRequestID: "ID of the payment request to query"
```

### callback

Queries status of a payment request but also updates the db status from pending to successful if payment was successful.

```ruby
POST /callback
Params:
- You can send the whole response object from /pay or /b2c and it will be processed.
- Example response object from /b2c
{
    "success": true,
    "b2c_transaction": {
        "id": 8,
        "transaction_id": "AG_20240401_201055e76349a83f60b8",
        "conversation_id": "962d9a78-0c73-4187-9491-e1a1b6cc7f15",
        "response_code": "0",
        "response_description": "Accept the service request successfully.",
        "status": "pending",
        "created_at": "2024-04-01T13:34:47.201Z",
        "updated_at": "2024-04-01T13:34:47.201Z",
        "phoneNumber": "",
        "amount": "100"
    }
}
```

### b2c

Pay out to a phone number.

```ruby
POST /b2c
Params:
- phoneNumber: "Phone number to which payment will be made"
- amount: "Amount to be paid"
```

## Dependencies

- `rest-client`: HTTP client for making API requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

- Mucha Naibei
- Email: muchajulius@gmail.com

Feel free to contribute and make this integration better!
