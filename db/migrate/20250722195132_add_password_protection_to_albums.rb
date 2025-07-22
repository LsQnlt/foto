class AddPasswordProtectionToAlbums < ActiveRecord::Migration[8.0]
  def change
    add_column :albums, :password_protected, :boolean
    add_column :albums, :password_digest, :string
  end
end
