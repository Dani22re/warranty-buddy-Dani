require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/dashboard/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /connect_gmail" do
    it "returns http success" do
      get "/dashboard/connect_gmail"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /upload" do
    it "returns http success" do
      get "/dashboard/upload"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /api_warranties" do
    it "returns http success" do
      get "/dashboard/api_warranties"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /api_health" do
    it "returns http success" do
      get "/dashboard/api_health"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /reset" do
    it "returns http success" do
      get "/dashboard/reset"
      expect(response).to have_http_status(:success)
    end
  end

end
