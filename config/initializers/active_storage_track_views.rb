module TrackBlobViews
  extend ActiveSupport::Concern

  included do
    after_action :record_page_view,
      if: -> { request.get? && response.successful? && trackable_lightbox? }
  end

  private

  def trackable_lightbox?
    params[:track] == "lightbox"
  end

  def record_page_view
    ActiveAnalytics.record_request(request)
  end
end


Rails.application.config.to_prepare do
  [
    ActiveStorage::Blobs::RedirectController,
    ActiveStorage::Blobs::ProxyController,
    ActiveStorage::Representations::RedirectController,
    ActiveStorage::Representations::ProxyController,
    ActiveStorage::DiskController
  ].each { |klass| klass.include TrackBlobViews }
end
