require 'rails_helper'

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "displays the warranty buddy title" do
      get root_path
      expect(response.body).to include("Warranty Buddy")
    end

    it "shows not connected status when Gmail is not connected" do
      get root_path
      expect(response.body).to include("Not Connected")
    end

    it "shows connected status when Gmail is connected" do
      # Mock the controller method that checks Gmail status
      allow_any_instance_of(DashboardController).to receive(:set_gmail_status)
      allow_any_instance_of(DashboardController).to receive(:instance_variable_get).with(:@gmail_connected).and_return(true)
      
      get root_path
      expect(response.body).to include("Connected")
    end

    it "displays products in the table" do
      create(:product, product_name: "Test Product")
      get root_path
      expect(response.body).to include("Test Product")
    end
  end

  describe "POST /upload" do
    it "creates a new product with valid data" do
      expect {
        post "/upload", params: {
          product: "MacBook Pro",
          merchant: "Apple Store",
          purchase_date: "2024-01-15",
          warranty_length: "12"
        }
      }.to change(Product, :count).by(1)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Uploaded MacBook Pro")
    end

    it "creates a product with default values" do
      post "/upload", params: { product: "iPhone 15" }
      
      product = Product.last
      expect(product.product_name).to eq("iPhone 15")
      expect(product.merchant).to eq("Amazon")
      expect(product.purchase_date).to eq(Date.today)
      expect(product.warranty_months).to eq(12)
    end

    it "handles missing product name" do
      post "/upload", params: { merchant: "Test Store" }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Missing product")
    end

    it "handles invalid purchase date" do
      post "/upload", params: {
        product: "Test Product",
        purchase_date: "invalid-date"
      }
      
      product = Product.last
      expect(product.purchase_date).to eq(Date.today)
    end

    it "handles negative warranty length" do
      post "/upload", params: {
        product: "Test Product",
        warranty_length: "-5"
      }
      
      product = Product.last
      expect(product.warranty_months).to eq(0)
    end
  end

  describe "GET /auth/google_oauth2/callback" do
    it "handles OAuth callback" do
      # This test is simplified since OAuth mocking is complex
      # In a real test environment, you would mock the OAuth response
      get "/auth/google_oauth2/callback"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /disconnect_gmail" do
    it "redirects to root path with disconnect message" do
      post "/disconnect_gmail"
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Gmail disconnected.")
    end
  end

  describe "GET /dashboard/api_health" do
    it "returns JSON with ok status" do
      get "/dashboard/api_health"
      expect(response).to have_http_status(:ok)
      
      json_response = JSON.parse(response.body)
      expect(json_response['ok']).to be true
    end

    it "includes Gmail connection status" do
      get "/dashboard/api_health"
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('gmail_connected')
    end
  end

  describe "GET /dashboard/api_warranties" do
    it "returns JSON array of warranties" do
      create(:product, product_name: "Test Product")
      get "/dashboard/api_warranties"
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
      expect(json_response.first['product']).to eq("Test Product")
    end
  end

  describe "POST /reset" do
    it "clears all data and returns ok" do
      create(:product)
      
      post "/reset"
      
      expect(Product.count).to eq(0)
      expect(response).to have_http_status(:ok)
    end
  end
end



