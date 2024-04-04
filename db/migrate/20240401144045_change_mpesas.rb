class ChangeMpesas < ActiveRecord::Migration[7.0]
  def change
    change_column_default :mpesas, :status, from: nil, to: 'pending'
    change_column :mpesas, :mpesaReceiptNumber, :string, default: 'placeholder'
  end
end
