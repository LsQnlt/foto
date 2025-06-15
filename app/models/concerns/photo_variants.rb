module PhotoVariants
  extend ActiveSupport::Concern

  PHOTO_SIZES = {
    thumb: [ 400, 300 ],
    lightbox: [ 1800, 1350 ],
    full: [ 2048, 2048 ]
  }.freeze

  def photo_variant(photo, name, method: :resize_to_limit)
    size = PHOTO_SIZES[name]
    photo.image.variant(method => size)
  end
end
