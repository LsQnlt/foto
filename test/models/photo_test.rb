# == Schema Information
#
# Table name: photos
#
#  id          :integer          not null, primary key
#  image       :string
#  likes_count :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  album_id    :integer          not null
#
# Indexes
#
#  index_photos_on_album_id  (album_id)
#
# Foreign Keys
#
#  album_id  (album_id => albums.id)
#
require "test_helper"

class PhotoTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
