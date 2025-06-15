class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def record_page_view
    if response.content_type && response.content_type.start_with?("text/html")
      ActiveAnalytics.record_request(request)
    end
  end
end
