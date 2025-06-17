class PhotosController < ApplicationController
  allow_unauthenticated_access only: :like

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
      render json: { error: "Impossible de sauvegarder" }, status: :unprocessable_entity
    end
  end
end
