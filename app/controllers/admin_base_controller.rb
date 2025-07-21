class AdminBaseController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    raise ActionController::RoutingError, "Not Found" unless authenticated?
  end
end
