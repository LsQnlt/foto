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
  # Specify parameters which should be permitted for assignment
  permit_params :title, :description, :published, uploaded_photos: []

  # or consider:
  #
  # permit_params do
  #   permitted = [:title, :description, :user_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []
  member_action :delete_photo, method: :delete do
    photo = Photo.find_by(id: params[:photo_id], album_id: params[:album_id])
    if photo
      photo.destroy
      redirect_back fallback_location: admin_album_path(params[:album_id]), notice: "Photo supprimée avec succès."
    else
      redirect_back fallback_location: admin_album_path(params[:album_id]), alert: "Photo introuvable."
    end
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
    end

    panel "Photos" do
      table_for album.photos do
        column :id
        column "Photo" do |photo|
          image_tag photo.thumb_variant(method: :resize_to_fill), size: "400x300" if photo.image.attached?
        end
        column "Actions" do |photo|
          link_to "Supprimer", delete_photo_admin_album_path(album_id: album.id, photo_id: photo.id),
                  method: :delete,
                  data: { confirm: "Êtes-vous sûr de vouloir supprimer cette photo ?" }
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
    end
    f.actions
  end

  controller do
    # Toutes les requêtes qui partent de Album (index, show, etc.)
    # utiliseront maintenant le eager-loading et éviteront les N+1
    def scoped_collection
      super.includes(photos: [ image_attachment: :blob ])
    end

    def create
      @album = Album.new(permitted_params[:album])
      @album.user = Current.user
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
      super do |success, _failure|
        if params[:album][:uploaded_photos].present?
          params[:album][:uploaded_photos].each do |uploaded_file|
            resource.photos.create(image: uploaded_file)
          end
        end
        redirect_to resource_path(resource) and return
      end
    end
  end
end
