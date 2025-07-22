class PhotosController < ApplicationController
  allow_unauthenticated_access only: [:like, :track_view]

  def like
    @photo = Photo.find(params[:id])
    session[:liked_photos] ||= []
    if session[:liked_photos].include?(@photo.id)
      render json: { already_liked: true }, status: :unprocessable_entity
      return
    end

    @photo.likes_count += 1

    if @photo.save
      session[:liked_photos] << @photo.id
      render json: { likes_count: @photo.likes_count, liked: true }
    else
      render json: { error: I18n.t('photos.like.error') }, status: :unprocessable_entity
    end
  end

  def track_view
    photo = Photo.find(params[:id])
    url = Rails.application.routes.url_helpers.rails_blob_path(photo.image, only_path: true)

    # On simule une "vraie" vue de cette image
    request.path_info = url
    ActiveAnalytics.record_request(request)
    head :ok
  end
end
