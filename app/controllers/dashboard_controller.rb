class DashboardController < ApplicationController
  protect_from_forgery with: :exception
  before_action :set_gmail_status

  def index
    @title = "Warranty Buddy  -  Iteration 1"
    @subtitle = "Your Digital Memory for Every Purchase"
    
    # Handle search and filtering
    @search_term = params[:search]
    @status_filter = params[:status]
    @merchant_filter = params[:merchant]
    @sort_by = params[:sort] || 'expiry_date'
    
    # Only show warranties for the current user
    if @gmail_connected && session[:gmail_uid]
      @warranties = Product.for_user(session[:gmail_uid])
    else
      @warranties = Product.none # Show no warranties if not connected
    end
    
    # Apply search
    @warranties = @warranties.search(@search_term) if @search_term.present?
    
    # Apply status filter
    case @status_filter
    when 'active'
      @warranties = @warranties.active
    when 'expired'
      @warranties = @warranties.expired
    when 'expiring_soon'
      @warranties = @warranties.expiring_soon
    end
    
    # Apply merchant filter
    @warranties = @warranties.by_merchant(@merchant_filter) if @merchant_filter.present?
    
    # Get unique merchants for filter dropdown (only for current user) - before ordering
    @merchants = @warranties.distinct.pluck(:merchant).compact.sort
    
    # Apply sorting
    case @sort_by
    when 'expiry_date'
      @warranties = @warranties.order(:purchase_date, :warranty_months)
    when 'product_name'
      @warranties = @warranties.order(:product_name)
    when 'purchase_date'
      @warranties = @warranties.order(:purchase_date)
    when 'merchant'
      @warranties = @warranties.order(:merchant)
    end
    
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

    unless @gmail_connected && session[:gmail_uid]
      redirect_to root_path, alert: "Please connect your Gmail account first"
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
      merchant: params[:merchant].presence || "",
      purchase_date: purchase_date,
      warranty_months: warranty_months,
      issue_description: params[:issue_description],
      gmail_uid: session[:gmail_uid]
    )

    redirect_to root_path, notice: "Uploaded #{params[:product]}"
  end

  def api_warranties
    if @gmail_connected && session[:gmail_uid]
      warranties = Product.for_user(session[:gmail_uid])
    else
      warranties = Product.none
    end
    
    render json: warranties.map { |p|
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
    # Clear session but keep warranties - they will reappear when user logs back in
    session[:gmail_uid] = nil
    session[:gmail_token] = nil
    session[:gmail_refresh_token] = nil
    head :ok
  end

  def disconnect_gmail
    # Clear session but keep warranties - they will reappear when user logs back in
    session[:gmail_uid] = nil
    session[:gmail_token] = nil
    session[:gmail_refresh_token] = nil
    redirect_to root_path, notice: "Gmail disconnected. Your warranties are saved and will reappear when you reconnect."
  end

  def parse_gmail_receipts
    return redirect_to root_path, alert: "Gmail not connected" unless @gmail_connected

    begin
      gmail_service = GmailService.new(session[:gmail_token])
      parsed_receipts = gmail_service.parse_receipt_emails

      created_count = 0
      parsed_receipts.each do |receipt_data|
        next if receipt_data[:product_name].blank?
        
        # Check if product already exists (by email ID or similar product)
        existing_product = Product.find_by(raw_email_id: receipt_data[:raw_email_id])
        next if existing_product

        Product.create!(
          product_name: receipt_data[:product_name],
          merchant: receipt_data[:merchant].presence || "",
          purchase_date: receipt_data[:purchase_date] || Date.today,
          warranty_months: receipt_data[:warranty_months] || 12,
          warranty_type: receipt_data[:warranty_type],
          return_policy_days: receipt_data[:return_policy_days],
          return_deadline: receipt_data[:return_deadline],
          source: receipt_data[:source],
          raw_email_id: receipt_data[:raw_email_id],
          confidence: receipt_data[:confidence],
          gmail_uid: session[:gmail_uid]
        )
        created_count += 1
      end

      if created_count == 0
        redirect_to root_path, notice: "No new receipts found in your Gmail. Using Google Gemini AI for intelligent receipt parsing."
      else
        redirect_to root_path, notice: "Successfully parsed #{created_count} receipts from Gmail using Google Gemini AI"
      end
    rescue => e
      Rails.logger.error "Gmail parsing failed: #{e.message}"
      message = e.message.to_s
      if message.include?("PERMISSION_DENIED") || message.include?("SERVICE_DISABLED") || message.include?("accessNotConfigured")
        alert_msg = "Gmail API is disabled for your Google Cloud project. Please enable it here (must be owner): https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=#{Rails.application.credentials.dig(:google, :project_id) || 'YOUR_PROJECT_ID'}"
        redirect_to root_path, alert: alert_msg
      else
        redirect_to root_path, alert: "Failed to parse Gmail receipts: #{e.message}"
      end
    end
  end

  def check_warranty_eligibility
    unless @gmail_connected && session[:gmail_uid]
      respond_to do |format|
        format.json { render json: { error: "Gmail not connected" }, status: :unauthorized }
        format.html { redirect_to root_path, alert: "Please connect your Gmail account first" }
      end
      return
    end

    product = Product.for_user(session[:gmail_uid]).find(params[:product_id])
    issue_description = params[:issue_description]

    if issue_description.blank?
      respond_to do |format|
        format.json { render json: { error: "Please describe the issue" }, status: :bad_request }
        format.html { redirect_to root_path, alert: "Please describe the issue" }
      end
      return
    end

    result = product.check_warranty_eligibility(issue_description)
    
    respond_to do |format|
      format.json { render json: result }
      format.html { redirect_to root_path, notice: result['reasoning'] }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { error: "Product not found" }, status: :not_found }
      format.html { redirect_to root_path, alert: "Product not found" }
    end
  end

  def lookup_warranty_info
    product_name = params[:product_name]
    merchant = params[:merchant]

    ai_service = AiService.new
    warranty_info = ai_service.lookup_warranty_info(product_name, merchant)

    respond_to do |format|
      format.json { render json: warranty_info }
    end
  end

  private

  def set_gmail_status
    @gmail_connected = session[:gmail_token].present?
  end
end
