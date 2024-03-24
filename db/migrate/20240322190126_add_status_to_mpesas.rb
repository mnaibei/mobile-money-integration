class AddStatusToMpesas < ActiveRecord::Migration[7.0]
  def change
    add_column :mpesas, :status, :string
  end
end
