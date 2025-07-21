class PagesController < ApplicationController
  allow_unauthenticated_access only: [:a_propos, :contact]
  def a_propos
  end

  def contact
  end
end
