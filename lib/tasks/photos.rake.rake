namespace :photos do
  processed = 0
  task process_all: :environment do
    Photo.find_each do |photo|
      next unless photo.image.attached?

      # size_mb = (photo.image.blob.byte_size.to_f / 1.megabyte).round(2)
      # puts "📸 Traitement photo ID #{photo.id} (#{filename}, #{size_mb} Mo)..."
      # OptimizePhotoJob.perform_later(photo.id)
      # processed += 1
      filename = photo.image.blob.filename
      old_size_mb = (photo.image.blob.byte_size.to_f / 1.megabyte).round(2)
      puts "📸 Traitement photo ID #{photo.id} (#{filename} (avant : #{old_size_mb} Mo)"

      # 🔁 Exécution synchrone pour voir l'effet immédiatement
      OptimizePhotoJob.perform_now(photo.id)

      # Recharger le blob mis à jour
      photo.reload
      new_size_mb = (photo.image.blob.byte_size.to_f / 1.megabyte).round(2)

      puts "✅ Photo ID #{photo.id} optimisée (après : #{new_size_mb} Mo)"
      processed += 1
    end
    puts "✅ #{processed} job(s) ProcessPhotoJob en file."
  end
end
