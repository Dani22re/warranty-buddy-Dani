class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :product_name
      t.string :merchant
      t.date :purchase_date
      t.integer :warranty_months
      t.text :issue_description

      t.timestamps
    end
  end
end
