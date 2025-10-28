FactoryBot.define do
  factory :product do
    product_name { "MyString" }
    merchant { "MyString" }
    purchase_date { "2025-10-28" }
    warranty_months { 1 }
    issue_description { "MyText" }
  end
end
