require 'google/apis/gmail_v1'

class GmailService
  Gmail = Google::Apis::GmailV1

  def initialize(access_token)
    @service = Gmail::GmailService.new
    @service.authorization = access_token
    @ai_service = AiService.new
  end

  def list_messages(user_id = 'me', query = '')
    result = @service.list_user_messages(user_id, q: query)
    result.messages || []
  end

  def get_message(message_id, user_id = 'me')
    @service.get_user_message(user_id, message_id)
  end

  def parse_receipt_emails(user_id = 'me')
    # Return empty array if no valid token
    return [] unless @service.authorization

    begin
      # Use AI to intelligently search for receipt emails - much broader approach
      # Search for emails that might contain purchase/receipt information
      receipt_queries = [
        # Broad search for purchase-related emails
        'subject:(receipt OR confirmation OR order OR purchase OR invoice OR bill OR payment OR shipped OR delivered) newer_than:1y',
        
        # Search for emails with common receipt keywords in body
        'has:attachment (receipt OR invoice OR order OR confirmation) newer_than:1y',
        
        # Search for emails from common retail domains (but not restrictive)
        'from:(amazon.com OR apple.com OR google.com OR microsoft.com OR adobe.com OR spotify.com OR netflix.com OR uber.com OR lyft.com OR doordash.com OR grubhub.com OR instacart.com OR walmart.com OR target.com OR costco.com OR bestbuy.com OR homedepot.com OR lowes.com OR staples.com OR officedepot.com OR gamestop.com OR newegg.com OR dell.com OR hp.com OR lenovo.com OR samsung.com OR sony.com OR lg.com OR canon.com OR nikon.com OR adidas.com OR nike.com OR underarmour.com OR puma.com OR reebok.com OR zappos.com OR footlocker.com OR finishline.com OR dickssportinggoods.com OR ulta.com OR sallybeauty.com OR sephora.com OR nordstrom.com OR macys.com OR kohls.com OR wayfair.com OR overstock.com OR etsy.com OR ebay.com OR shopify.com OR squareup.com OR bedbathandbeyond.com) newer_than:1y',
        
        # Search for emails with tracking/shipping info
        'subject:(tracking OR shipment OR shipped OR delivered OR out for delivery) newer_than:1y',
        
        # Search for subscription/recurring payment emails
        'subject:(subscription OR renewal OR billing OR payment) newer_than:1y',
        
        # Search for warranty/registration emails
        'subject:(warranty OR registration OR product registration OR device registration) newer_than:1y'
      ]
      
      all_messages = []
      receipt_queries.each do |query|
        messages = list_messages(user_id, query)
        all_messages.concat(messages)
      end

      # Remove duplicates and let AI determine if each message is actually a receipt
      unique_messages = all_messages.uniq { |msg| msg.id }
      parsed_receipts = []

      unique_messages.each do |message|
        begin
          full_message = get_message(message.id, user_id)
          parsed_receipt = parse_single_receipt(full_message)
          parsed_receipts << parsed_receipt if parsed_receipt
        rescue => e
          Rails.logger.error "Failed to parse message #{message.id}: #{e.message}"
        end
      end

      parsed_receipts
    rescue => e
      Rails.logger.error "Gmail API error: #{e.message}"
      []
    end
  end

  private

  def parse_single_receipt(message)
    # Extract email content
    email_content = extract_email_content(message)
    return nil if email_content.blank?

    # Use AI to determine if this is a receipt and extract information
    ai_data = @ai_service.extract_receipt_info(email_content)
    return nil unless ai_data # AI determined this is not a receipt or extraction failed

    # Convert to Product attributes
    {
      product_name: ai_data['product_name'],
      merchant: ai_data['merchant'],
      purchase_date: parse_date(ai_data['purchase_date']),
      warranty_months: ai_data['warranty_length_months'] || 12, # Default to 12 months if not specified
      warranty_type: ai_data['warranty_type'],
      return_policy_days: ai_data['return_policy_days'],
      return_deadline: parse_date(ai_data['return_deadline']),
      confidence: ai_data['confidence'],
      source: 'gmail_ai_parsed',
      raw_email_id: message.id
    }
  end

  def extract_email_content(message)
    content = ""
    
    if message.payload.parts
      message.payload.parts.each do |part|
        if part.mime_type == 'text/plain' || part.mime_type == 'text/html'
          if part.body.data
            content += Base64.urlsafe_decode64(part.body.data)
          end
        end
      end
    elsif message.payload.body.data
      content = Base64.urlsafe_decode64(message.payload.body.data)
    end

    # Clean up HTML if present
    if content.include?('<')
      doc = Nokogiri::HTML(content)
      content = doc.text
    end

    content
  end

  def parse_date(date_string)
    return Date.today unless date_string
    
    Date.parse(date_string)
  rescue ArgumentError
    Date.today
  end
end
