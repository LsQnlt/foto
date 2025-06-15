class OptimizePhotoJob < ActiveJob::Base
  queue_as :default

  VARIANTS = {
    thumb: [ 400, 300 ],
    lightbox: [ 1200, 900 ]
  }

  def perform(photo_id)
    photo = Photo.find_by(id: photo_id)
    begin
      optimize_original(photo)
      generate_variants(photo)
    rescue => e
      Rails.logger.error("[OptimizePhotoJob] Échec traitement photo #{photo_id} : #{e.class} #{e.message}")
    end
  end

  private

    def optimize_original(photo)
      require "image_processing/mini_magick"

      original_name = photo.image.blob.filename

      photo.image.open do |file|
        processed = ImageProcessing::MiniMagick
                      .source(file)
                      .resize_to_limit(2000, 2000)
                      .convert("jpeg")
                      .strip
                      .saver(quality: 75)
                      .call

        # Attacher à la place de l'ancien
        photo.image.attach(
          io: processed,
          filename: "#{original_name}",
          content_type: "image/jpeg"
        )
      end
    end

    def generate_variants(photo)
      VARIANTS.each_value { |size| photo.image.variant(resize_to_limit: size).processed }
    end
end
