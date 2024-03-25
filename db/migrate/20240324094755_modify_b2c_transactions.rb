class ModifyB2cTransactions < ActiveRecord::Migration[7.0]
  def change
    add_column :b2c_transactions, :phoneNumber, :string
    add_column :b2c_transactions, :amount, :string
  end
end
