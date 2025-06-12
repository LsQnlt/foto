class AlbumsController < ApplicationController
  before_action :set_album, only: %i[ show ]
  skip_before_action :require_authentication, only: [ :index, :show ]
  # GET /albums or /albums.json
  def index
    @albums = Album.all
  end

  # GET /albums/1 or /albums/1.json
  def show
    @liked_photos = session[:liked_photos] || []
  end

  private
  def set_album
    @album = Album.find(params[:id])
  end
end
