# == Schema Information
#
# Table name: photos
#
#  id         :integer          not null, primary key
#  image      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  album_id   :integer          not null
#
# Indexes
#
#  index_photos_on_album_id  (album_id)
#
# Foreign Keys
#
#  album_id  (album_id => albums.id)
#
ActiveAdmin.register Photo do
  # Specify parameters which should be permitted for assignment
  permit_params :image, :album_id

  # or consider:
  #
  # permit_params do
  #   permitted = [:image, :album_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Add or remove filters to toggle their visibility
  filter :id
  filter :image
  filter :album
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :image
    column "Nom de l'image" do |photo|
      photo.image.filename.to_s if photo.image.attached?
    end
    column "Poid de l'image en Mo" do |photo|
      (photo.image.blob.byte_size.to_f / 1.megabyte).round(2).to_s if photo.image.attached?
    end
    column :album
    column :created_at
    column :updated_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :image do |ad|
        image_tag url_for(ad.image)
      end
      row :album
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :image,  as: :file
      f.input :album
    end
    f.actions
  end

  controller do
    def scoped_collection
      super.includes(image_attachment: :blob)
           .references(:blob)
           .order("active_storage_blobs.filename ASC")
    end
  end
end
