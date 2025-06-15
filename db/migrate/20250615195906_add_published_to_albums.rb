class AddPublishedToAlbums < ActiveRecord::Migration[8.0]
  def change
    add_column :albums, :published, :boolean, default: false
  end
end
