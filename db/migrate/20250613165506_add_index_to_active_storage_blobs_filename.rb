class AddIndexToActiveStorageBlobsFilename < ActiveRecord::Migration[8.0]
  def change
    add_index :active_storage_blobs, :filename
  end
end
