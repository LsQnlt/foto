class AlbumsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user
  before_action :set_album, only: [:show, :verify_password]
  before_action :redirect_unless_unlocked, only: [:show]
  after_action :record_page_view, only: [:show]

  def index
    @albums = Album
      .where(user_id: @user.id)
      .includes(cover_photo: { image_attachment: :blob })
      .published
      .order('created_at DESC')
  end

  def show
    @photos = @album.photos
      .includes(image_attachment: :blob)
      .references(:blob)
      .order(:created_at)
    @liked_photos = session[:liked_photos] || []
  end

  def verify_password
    if request.post?
      if @album.authenticate(params[:password])
        unlock_album(@album)
        redirect_to user_album_path(@album, pseudonym: @user.pseudonym)
      else
        flash.now[:alert] = t('.incorrect')
        render :verify_password, status: :unprocessable_entity
      end
    end
  end

  private

  def redirect_unless_unlocked
    return unless @album.password_protected?
    return if album_unlocked?(@album)

    redirect_to verify_password_user_album_path(@album, pseudonym: @user.pseudonym)
  end

  def album_unlocked?(album)
    session[:unlocked_albums]&.include?(album.id)
  end

  def unlock_album(album)
    session[:unlocked_albums] ||= []
    session[:unlocked_albums] << album.id unless album_unlocked?(album)
  end

  def set_user
    @user = User.find_by!(pseudonym: params[:pseudonym])
  end

  # Un brouillon n'existe pas pour le public : 404, sauf pour son propriétaire ou un admin
  def set_album
    @album = @user.albums.includes(:photos).find(params[:id])
    resume_session
    raise ActiveRecord::RecordNotFound unless policy(@album).show?
  end
end
