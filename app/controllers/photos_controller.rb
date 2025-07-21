class PhotosController < ApplicationController
  allow_unauthenticated_access only: [:like, :track_view]

  def like
    @photo = Photo.find(params[:id])
    session[:liked_photos] ||= []
    if session[:liked_photos].include?(@photo.id)
      render json: { already_liked: true }, status: :unprocessable_entity
      return
    end

    @photo.increment!(:likes_count)

    if @photo.save
      session[:liked_photos] << @photo.id
      render json: { likes_count: @photo.likes_count, liked: true }
    else
      render json: { error: "Impossible de sauvegarder" }, status: :unprocessable_entity
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
