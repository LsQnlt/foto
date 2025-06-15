class AlbumsController < ApplicationController
  before_action :set_album, only: %i[ show ]
  skip_before_action :require_authentication, only: [ :index, :show ]
  after_action :record_page_view, only: %i[ show ]

  # GET /albums or /albums.json
  def index
    @albums = Album
      .includes(cover_photo: { image_attachment: :blob })
      .published
      .order(:title)
  end

  # GET /albums/1 or /albums/1.json
  def show
    @photos = @album
      .photos
      .includes(image_attachment: :blob)
      .references(:blob)
      .order("active_storage_blobs.filename ASC")

    @liked_photos = session[:liked_photos] || []
  end

  private
    def set_album
      @album = Album.includes(:photos).find(params[:id])
    end
end
