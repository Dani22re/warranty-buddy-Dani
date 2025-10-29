#!/usr/bin/env ruby

# Debug script to test Gmail service
# Run with: rails runner debug_gmail.rb

puts "🔍 Starting Gmail Service Debug"
puts "=" * 50

# Check if we have credentials
begin
  api_key = Rails.application.credentials.dig(:google, :gemini_api_key)
  if api_key.present?
    puts "✅ Gemini API key found (length: #{api_key.length})"
  else
    puts "❌ No Gemini API key found in credentials"
    puts "   Please add it with: rails credentials:edit"
    puts "   Add: google:"
    puts "     gemini_api_key: YOUR_API_KEY_HERE"
    exit 1
  end
rescue => e
  puts "❌ Error accessing credentials: #{e.message}"
  exit 1
end

# Test AI service initialization
puts "\n🤖 Testing AI Service..."
begin
  ai_service = AiService.new
  if ai_service.instance_variable_get(:@client)
    puts "✅ AI Service initialized successfully"
  else
    puts "❌ AI Service failed to initialize"
    exit 1
  end
rescue => e
  puts "❌ AI Service error: #{e.message}"
  exit 1
end

# Test with a sample email content
puts "\n📧 Testing AI with sample email..."
sample_email = <<~EMAIL
  Subject: Your Amazon.com order has shipped
  
  Hello,
  
  Your order has been shipped and is on its way to you.
  
  Order Details:
  Order Number: 123-4567890-1234567
  Item: Apple iPhone 15 Pro Max 256GB
  Price: $1,199.00
  Shipping Address: 123 Main St, City, State 12345
  
  Tracking Number: 1Z999AA1234567890
  Carrier: UPS
  
  Expected Delivery: December 15, 2024
  
  Thank you for your order!
  
  Amazon.com
EMAIL

begin
  result = ai_service.extract_receipt_info(sample_email)
  if result
    puts "✅ AI successfully identified receipt:"
    puts "   Product: #{result['product_name']}"
    puts "   Merchant: #{result['merchant']}"
    puts "   Confidence: #{result['confidence']}"
  else
    puts "❌ AI did not identify this as a receipt"
  end
rescue => e
  puts "❌ AI test error: #{e.message}"
end

puts "\n" + "=" * 50
puts "🔍 Debug complete!"
puts "\nTo test with real Gmail data, you'll need to:"
puts "1. Set up OAuth2 credentials for Gmail API"
puts "2. Get an access token from a user"
puts "3. Call GmailService.new(access_token).parse_receipt_emails"
