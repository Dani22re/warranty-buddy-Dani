class AiService
  def initialize
    begin
      require 'gemini-ai'
      @client = Gemini.new(
        credentials: {
          service: 'generative-language-api',
          api_key: Rails.application.credentials.dig(:google, :gemini_api_key) || 'AIzaSyDijb5niCKfGIhjfxaRO8CouEykHSIdcXs'
        },
        options: { model: 'gemini-2.0-flash', server_sent_events: false }
      )
    rescue LoadError => e
      Rails.logger.error "Gemini AI gem not available: #{e.message}"
      @client = nil
    rescue => e
      Rails.logger.error "Gemini AI client initialization failed: #{e.message}"
      @client = nil
    end
  end

  def extract_receipt_info(email_content)
    return nil unless @client

    prompt = <<~PROMPT
      Analyze this email and determine if it contains purchase/receipt information for a physical product that would have warranty coverage, return policies, or other important deadlines.
      
      First, determine if this is actually a receipt for a physical product purchase. Look for:
      - Product names, descriptions, or SKUs
      - Purchase amounts, prices, or totals
      - Order numbers or confirmation numbers
      - Shipping information
      - Merchant/store information
      
      If this is NOT a receipt for a physical product (e.g., subscription, service, digital download, newsletter, etc.), return: {"is_receipt": false}
      
      If this IS a receipt for a physical product, extract the following information and return a JSON object:
      {
        "is_receipt": true,
        "product_name": "exact product name or description",
        "merchant": "store/website/company name",
        "purchase_date": "YYYY-MM-DD format",
        "warranty_length_months": number (only if explicitly mentioned, otherwise null),
        "warranty_type": "manufacturer/merchant/extended" (only if mentioned, otherwise null),
        "return_policy_days": number (return deadline in days, if mentioned),
        "return_deadline": "YYYY-MM-DD format" (specific return deadline date, if mentioned),
        "confidence": 0.0-1.0 (how confident you are this is a valid receipt)
      }
      
      Look for warranty information, return policies, exchange deadlines, and any other important dates/deadlines related to the purchase.
      
      Be very conservative - only return is_receipt: true if you're confident this is a physical product purchase receipt.
      
      Email content:
      #{email_content[0..2000]}...
    PROMPT

    response = @client.generate_content({
      contents: { role: "user", parts: { text: prompt } }
    })

    response_text = response.dig("candidates", 0, "content", "parts", 0, "text")
    
    # Clean up markdown code blocks if present
    response_text = response_text.gsub(/```json\s*/, '').gsub(/```\s*$/, '').strip
    
    result = JSON.parse(response_text)
    
    # Only return data if AI confirms this is a receipt
    return nil unless result["is_receipt"] == true
    
    result
  rescue => e
    Rails.logger.error "AI extraction failed: #{e.message}"
    nil
  end

  def lookup_warranty_info(product_name, merchant = nil)
    return nil unless @client

    prompt = <<~PROMPT
      Look up warranty information for this product. Return a JSON object with:
      {
        "standard_warranty_months": number,
        "warranty_terms": "brief description of what's covered",
        "exclusions": "what's not covered",
        "return_policy_days": number,
        "confidence": 0.0-1.0
      }
      
      Product: #{product_name}
      Merchant: #{merchant || "unknown"}
      
      Be conservative and only include information you're confident about.
    PROMPT

    response = @client.generate_content({
      contents: { role: "user", parts: { text: prompt } }
    })

    response_text = response.dig("candidates", 0, "content", "parts", 0, "text")
    
    # Clean up markdown code blocks if present
    response_text = response_text.gsub(/```json\s*/, '').gsub(/```\s*$/, '').strip
    
    JSON.parse(response_text)
  rescue => e
    Rails.logger.error "AI warranty lookup failed: #{e.message}"
    nil
  end

  def check_warranty_eligibility(product_name, issue_description, warranty_terms)
    return nil unless @client

    prompt = <<~PROMPT
      Determine if this product issue is covered under warranty. Return a JSON object with:
      {
        "is_covered": true/false,
        "reasoning": "explanation of decision",
        "recommended_action": "what the user should do",
        "confidence": 0.0-1.0
      }
      
      Product: #{product_name}
      Issue: #{issue_description}
      Warranty Terms: #{warranty_terms}
    PROMPT

    response = @client.generate_content({
      contents: { role: "user", parts: { text: prompt } }
    })

    response_text = response.dig("candidates", 0, "content", "parts", 0, "text")
    
    # Clean up markdown code blocks if present
    response_text = response_text.gsub(/```json\s*/, '').gsub(/```\s*$/, '').strip
    
    JSON.parse(response_text)
  rescue => e
    Rails.logger.error "AI warranty eligibility check failed: #{e.message}"
    nil
  end

end
