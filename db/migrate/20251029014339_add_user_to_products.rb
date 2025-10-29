class AddUserToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :gmail_uid, :string
  end
end
