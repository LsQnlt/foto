class PhotosController < ApplicationController
  def like
    @photo = Photo.find(params[:id])
    session[:liked_photos] ||= []
    if session[:liked_photos].include?(@photo.id)
      render json: { likes_count: @photo.likes_count, liked: true }, status: :unprocessable_entity
      return
    end

    @photo.increment!(:likes_count)
    session[:liked_photos] << @photo.id
    render json: { likes_count: @photo.likes_count, liked: true }
  end
end
