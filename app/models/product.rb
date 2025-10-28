class Product < ApplicationRecord
  validates :product_name, presence: true

  def expiry_date
    return nil unless purchase_date && warranty_months
    (purchase_date.to_date >> warranty_months) # add months
  end
end
