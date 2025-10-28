class DashboardController < ApplicationController
  protect_from_forgery with: :exception

  def index
    @title = "Warranty Buddy  -  Iteration 1"
    @subtitle = "Your Digital Memory for Every Purchase"
    @gmail_connected = session[:gmail_connected] || false
    @warranties = Product.order(:id)
  end

  def connect_gmail
    session[:gmail_connected] = true
    flash[:notice] = "Gmail (Mock) connected successfully."
    redirect_to root_path
  end

  def upload
    if params[:product].blank?
      respond_to do |format|
        format.html { flash[:alert] = "Missing product"; redirect_to root_path }
        format.json { head :bad_request }
      end
      return
    end

    Product.create!(
      product_name: params[:product],
      merchant: params[:merchant].presence || "Amazon",
      purchase_date: Date.today,
      warranty_months: (params[:warranty_length].presence || 12).to_i,
      issue_description: params[:issue_description]
    )

    redirect_to root_path, notice: "Uploaded #{params[:product]}"
  end

  def api_warranties
    render json: Product.all.map { |p|
      {
        id: p.id,
        product: p.product_name,
        merchant: p.merchant,
        purchase_date: p.purchase_date,
        warranty_length_months: p.warranty_months
      }
    }
  end

  def api_health
    render json: { ok: true, gmail_connected: (session[:gmail_connected] || false) }, status: :ok
  end

  def reset
    session[:gmail_connected] = false
    Product.delete_all
    head :ok
  end
end
