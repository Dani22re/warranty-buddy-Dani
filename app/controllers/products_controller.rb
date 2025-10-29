class ProductsController < ApplicationController
    require "csv"
  
    # Export all warranties for the connected Gmail user as CSV
    def export
      unless session[:gmail_uid]
        redirect_to root_path, alert: "Please connect Gmail first."
        return
      end
  
      # Fetch warranties for the current Gmail user
      products = Product.for_user(session[:gmail_uid]).to_a.sort_by do |p|
        # Sort by computed expiry_date, put nils at the end
        p.expiry_date || Date.new(3000, 1, 1)
      end
  
      respond_to do |format|
        format.csv do
          headers["Content-Disposition"] = "attachment; filename=warranties.csv"
          headers["Content-Type"]        = "text/csv"
  
          render plain: CSV.generate(headers: true) { |csv|
            csv << %w[
              id
              product_name
              merchant
              purchase_date
              warranty_months
              expiry_date
              status
            ]
  
            products.each do |p|
              csv << [
                p.id,
                p.product_name,
                p.merchant,
                p.purchase_date,
                p.warranty_months,
                p.expiry_date,
                p.status  # uses your model’s status method
              ]
            end
          }
        end
      end
    end
  end
  