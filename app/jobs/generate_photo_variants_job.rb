class GeneratePhotoVariantsJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
  # queue_as :default

  VARIANTS = {
    thumb: [ 400, 300 ]
    # Add more if needed
  }

  def perform(photo_id)
    photo = Photo.find_by(id: photo_id)
    return unless photo&.image&.attached?

    VARIANTS.each do |_name, size|
      photo.image.variant(resize_to_fill: size).processed
    end
  end
end
