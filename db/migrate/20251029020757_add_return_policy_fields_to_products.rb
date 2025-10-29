class AddReturnPolicyFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :return_policy_days, :integer
    add_column :products, :return_deadline, :date
  end
end
