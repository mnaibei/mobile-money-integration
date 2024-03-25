class CreateB2cTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :b2c_transactions do |t|
      t.string :transaction_id
      t.string :conversation_id
      t.string :response_code
      t.string :response_description
      t.string :status, default: 'pending'

      t.timestamps
    end
  end
end
