module PhotoVariants
  extend ActiveSupport::Concern

  PHOTO_SIZES = {
    thumb: [400, 300],
    lightbox: [1800, 1350],
    full: [2048, 2048],
  }.freeze

  def lightbox_variant(method: :resize_to_limit)
    photo_variant(:lightbox, method:)
  end

  def thumb_variant(method: :resize_to_limit)
    photo_variant(:thumb, method:)
  end

  private

  def photo_variant(name, method:)
    image.variant(method => PHOTO_SIZES[name])
  end
end
