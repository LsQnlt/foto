class OptimizePhotoJob < ApplicationJob
  queue_as :default

  def perform(photo_id)
    photo = Photo.find_by(id: photo_id)
    return unless photo

    begin
      optimize_original(photo)
      photo.reload
      photo.image.reload
      generate_variants(photo)
    rescue => e
      Rails.logger.error("[OptimizePhotoJob] Échec traitement photo #{photo_id} : #{e.class} #{e.message}")
    end
  end

  private

  def optimize_original(photo)
    require "image_processing/vips"

    original_name = photo.image.blob.filename
    old_blob = photo.image.blob
    processed = nil

    photo.image.open do |file|
      processed = ImageProcessing::Vips
        .source(file)
        .resize_to_limit(2048, 2048)
        .convert("webp")
        .call
    end

    photo.image.attach(
      io: File.open(processed.path, "rb"),
      filename: "#{original_name.base}.webp",
      content_type: "image/webp",
    )
    old_blob.purge
  ensure
    processed&.close!
  end

  def generate_variants(photo)
    photo.thumb_variant(method: :resize_to_fill).processed
    photo.lightbox_variant(method: :resize_to_limit).processed
  end
end
