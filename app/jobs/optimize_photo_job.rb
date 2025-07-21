class OptimizePhotoJob < ApplicationJob
  queue_as :default

  def perform(photo_id)
    photo = Photo.find_by(id: photo_id)
    begin
      optimize_original(photo)
      photo.reload               # recharge l’objet
      photo.image.reload         # recharge le blob/attachment
      generate_variants(photo)
    rescue => e
      Rails.logger.error("[OptimizePhotoJob] Échec traitement photo #{photo_id} : #{e.class} #{e.message}")
    end
  end

  private

  def optimize_original(photo)
    require "image_processing/mini_magick"

    original_name = photo.image.blob.filename
    # 1. On crée le WebP DANS le bloc (fichier origine encore ouvert)
    processed = nil
    photo.image.open do |file|
      processed = ImageProcessing::MiniMagick
        .source(file)
        .resize_to_limit(2048, 2048)
        .auto_orient
        .convert("webp")
        .call
    end # <= ici l'ancien fichier est fermé, rien n'est encore purgé

    # 2. On remplace l’attachement une fois le bloc terminé
    photo.image.attach(
      io:  File.open(processed.path, "rb"), # Tempfile encore dispo
      filename: "#{original_name.base}.webp",
      content_type: "image/webp",
    )
  end

  def generate_variants(photo)
    photo.thumb_variant(method: :resize_to_fill).processed
    photo.lightbox_variant(method: :resize_to_limit).processed
  end
end
