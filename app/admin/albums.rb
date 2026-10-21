# == Schema Information
#
# Table name: albums
#
#  id          :integer          not null, primary key
#  description :text
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer          not null
#
# Indexes
#
#  index_albums_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
ActiveAdmin.register Album do
  permit_params do
    policy(Album).permitted_attributes
  end

  # For security, limit the actions that should be available
  actions :all, except: []
  member_action :delete_photo, method: :delete do
    photo = resource.photos.find_by(id: params[:photo_id])
    if photo
      authorize photo, :destroy?
      photo.destroy!
      redirect_back_or_to(admin_album_path(resource), notice: t('active_admin.albums.flash.photo_deleted'))
    else
      redirect_back_or_to(admin_album_path(resource), alert: t('active_admin.albums.flash.photo_not_found'))
    end
  end

  before_save do |album|
    authorize album
  end

  # Add or remove filters to toggle their visibility
  filter :id
  filter :title
  filter :description
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :title
    column :description
    column :created_at
    column :updated_at
    column :published
    column :password_protected
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :title
      row :description
      row :created_at
      row :updated_at
      row :published
      row :password_protected
    end

    panel t('active_admin.albums.panel.photos') do
      table_for album.photos do
        column :id
        column t('active_admin.albums.column.photo') do |photo|
          image_tag photo.thumb_variant(method: :resize_to_fill), size: "400x300" if photo.image.attached?
        end
        column "Actions" do |photo|
          link_to t('active_admin.albums.action.delete_photo'),
            delete_photo_admin_album_path(album, photo_id: photo.id),
            method: :delete,
            data: { confirm: t('active_admin.albums.confirm.delete_photo') }
        end
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :title
      f.input :description
      f.input :uploaded_photos, as: :file, input_html: { multiple: true }
      f.input :published
      f.input :password_protected, label: t('active_admin.albums.inputs.password_protected')
      f.input :password,
        as: :string,
        input_html: { autocomplete: "new-password" },
        hint: f.object.persisted? && f.object.password_protected? ? t('active_admin.albums.inputs.password_optional') : nil,
        label: t('active_admin.albums.inputs.password')
      if Current.user.has_role?(:admin)
        f.input :user_id,
          as: :select,
          collection: User.all.map { |u| [u.pseudonym, u.id] },
          include_blank: false,
          selected: Current.user.id
      end
    end
    f.actions
  end

  controller do
    def scoped_collection
      policy_scope(Album).includes(photos: [image_attachment: :blob])
    end

    def create
      @album = Album.new(permitted_params[:album])
      @album.user_id ||= Current.user.id
      if permitted_params[:album][:password_protected] == "1"
        @album.password = permitted_params[:album][:password]
      else
        @album.password_digest = nil
      end

      authorize @album

      if @album.save
        if params[:album][:uploaded_photos].present?
          params[:album][:uploaded_photos].each do |uploaded_file|
            @album.photos.create(image: uploaded_file)
          end
        end
        redirect_to resource_path(@album)
      else
        render :new
      end
    end

    def update
      params[:album][:password] = nil if params[:album][:password_protected] != "1"
      super do |success, failure|
        success.html do
          if params[:album][:uploaded_photos].present?
            params[:album][:uploaded_photos].each do |uploaded_file|
              resource.photos.create(image: uploaded_file)
            end
          end
          flash[:notice] = t('active_admin.albums.update.success')
          redirect_to resource_path(resource)
        end

        failure.html do
          render :edit
        end
      end
    end
  end
end
