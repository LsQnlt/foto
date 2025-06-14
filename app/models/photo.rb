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
class Photo < ApplicationRecord
  belongs_to :album
  has_one_attached :image

  validates :image, attached: true
  validates :image, content_type: { in: [ :png, :jpeg ], spoofing_protection: true }
  after_commit :generate_variants_async, on: :create

  def self.ransackable_attributes(auth_object = nil)
    [ "album_id", "created_at", "id", "image", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "album", "image_attachment", "image_blob" ]
  end

  private

    def generate_variants_async
      GeneratePhotoVariantsJob.perform_later(id)
    end
end
