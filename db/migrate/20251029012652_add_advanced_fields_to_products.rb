class AddAdvancedFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :warranty_type, :string
    add_column :products, :source, :string
    add_column :products, :raw_email_id, :string
    add_column :products, :confidence, :decimal, precision: 3, scale: 2
  end
end
