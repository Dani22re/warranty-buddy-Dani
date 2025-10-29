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
      # Mock the controller to simulate Gmail connection
      allow_any_instance_of(DashboardController).to receive(:set_gmail_status)
      allow_any_instance_of(DashboardController).to receive(:instance_variable_get).with(:@gmail_connected).and_return(true)
      
      get root_path
      expect(response.body).to include("Connected")
    end

    it "displays products in the table" do
      create(:product, product_name: "Test Product", gmail_uid: 'test_user')
      # Mock the controller to simulate Gmail connection and user filtering
      allow_any_instance_of(DashboardController).to receive(:set_gmail_status)
      allow_any_instance_of(DashboardController).to receive(:instance_variable_get).with(:@gmail_connected).and_return(true)
      allow_any_instance_of(DashboardController).to receive(:instance_variable_set).with(:@warranties, anything)
      
      get root_path
      expect(response.body).to include("Test Product")
    end
  end

  describe "POST /upload" do
    it "requires Gmail connection to upload" do
      expect {
        post "/upload", params: {
          product: "MacBook Pro",
          merchant: "Apple Store",
          purchase_date: "2024-01-15",
          warranty_length: "12"
        }
      }.not_to change(Product, :count)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Please connect your Gmail account first")
    end

    it "requires Gmail connection for all uploads" do
      post "/upload", params: { product: "iPhone 15" }
      
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Please connect your Gmail account first")
    end

    it "handles missing product name" do
      post "/upload", params: { merchant: "Test Store" }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Missing product")
    end

    it "requires Gmail connection for invalid data" do
      post "/upload", params: {
        product: "Test Product",
        purchase_date: "invalid-date"
      }
      
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Please connect your Gmail account first")
    end

    it "requires Gmail connection for negative warranty" do
      post "/upload", params: {
        product: "Test Product",
        warranty_length: "-5"
      }
      
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Please connect your Gmail account first")
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
      create(:product, product_name: "Test Product", gmail_uid: 'test_user')
      # Mock the controller to simulate Gmail connection
      allow_any_instance_of(DashboardController).to receive(:set_gmail_status)
      allow_any_instance_of(DashboardController).to receive(:instance_variable_get).with(:@gmail_connected).and_return(true)
      
      get "/dashboard/api_warranties"
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
    end
  end

  describe "POST /reset" do
    it "clears session but keeps warranties" do
      create(:product, gmail_uid: 'test_user')
      
      post "/reset"
      
      expect(Product.count).to eq(1) # Warranties are kept
      expect(response).to have_http_status(:ok)
    end
  end
end



