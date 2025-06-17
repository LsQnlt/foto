class AddDefaultValueToLikesCountToPhotos < ActiveRecord::Migration[8.0]
  def change
    change_column_default :photos, :likes_count, from: nil, to: 0
  end
end
