class DashboardController < ApplicationController
  protect_from_forgery with: :exception
  before_action :set_gmail_status

  def index
    @title = "Warranty Buddy  -  Iteration 1"
    @subtitle = "Your Digital Memory for Every Purchase"
    @warranties = Product.order(:id)
    # For iteration 1, we are not fetching Gmail messages yet
    @gmail_messages = []
  end


  # Called by OmniAuth callback
  def google_auth
    auth_info = request.env['omniauth.auth']

    session[:gmail_uid] = auth_info.uid
    session[:gmail_token] = auth_info.credentials.token
    session[:gmail_refresh_token] = auth_info.credentials.refresh_token

    flash[:notice] = "Gmail connected successfully!"
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

    purchase_date = begin
      Date.parse(params[:purchase_date])
    rescue ArgumentError, TypeError
      Date.today
    end

    warranty_months = (params[:warranty_length].presence || 12).to_i
    warranty_months = 0 if warranty_months.negative?

    Product.create!(
      product_name: params[:product],
      merchant: params[:merchant].presence || "Amazon",
      purchase_date: purchase_date,
      warranty_months: warranty_months,
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
    render json: { ok: true, gmail_connected: @gmail_connected }, status: :ok
  end

  def reset
    session[:gmail_uid] = nil
    session[:gmail_token] = nil
    session[:gmail_refresh_token] = nil
    Product.delete_all
    head :ok
  end

  def disconnect_gmail
    session[:gmail_uid] = nil
    session[:gmail_token] = nil
    session[:gmail_refresh_token] = nil
    redirect_to root_path, notice: "Gmail disconnected."
  end

  private

  def set_gmail_status
    @gmail_connected = session[:gmail_token].present?
  end
end
