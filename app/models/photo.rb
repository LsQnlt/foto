# == Schema Information
#
# Table name: photos
#
#  id          :integer          not null, primary key
#  image       :string
#  likes_count :integer          default(0)
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
  include PhotoVariants

  belongs_to :album
  has_one_attached :image

  validates :image, attached: true
  validates :image, content_type: { in: %w[image/png image/jpeg image/webp png jpeg webp], spoofing_protection: true }
  after_commit :generate_variants_async, on: :create

  def self.ransackable_attributes(auth_object = nil)
    ["album_id", "created_at", "id", "image", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["album", "image_attachment", "image_blob"]
  end

  def lightbox_variant(method: nil) # See PhotoVariants
    method.present? ? photo_variant(self, :lightbox_variant, method:) : photo_variant(self, :lightbox_variant)
  end

  def thumb_variant(method: nil) # See PhotoVariants
    method.present? ? photo_variant(self, :thumb, method:) : photo_variant(self, :thumb)
  end

  private

  def generate_variants_async
    OptimizePhotoJob.perform_later(id)
  end
end
