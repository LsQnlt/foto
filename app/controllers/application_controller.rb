# Foto - Copyright (C) 2025 Louis Quenault
#
# Licensed under the GNU AGPL v3.0.
# See the LICENSE file or https://www.gnu.org/licenses/agpl-3.0.html

class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def record_page_view
    if response.content_type&.start_with?("text/html")
      ActiveAnalytics.record_request(request)
    end
  end

  def pundit_user
    Current.user
  end

  private

  def user_not_authorized
    redirect_back_or_to root_path, alert: t("pundit.not_authorized")
  end
end
