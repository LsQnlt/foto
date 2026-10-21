namespace :photos do
  desc "Génère les variantes manquantes (vignette + lightbox) de toutes les photos"
  task generate_variants: :environment do
    total = Photo.count
    generated = 0
    failed = 0

    Photo.includes(image_attachment: :blob).find_each.with_index(1) do |photo, index|
      next unless photo.image.attached?

      [photo.thumb_variant(method: :resize_to_fill), photo.lightbox_variant].each do |variant|
        next if photo.image.blob.variant_records.exists?(variation_digest: variant.variation.digest)

        variant.processed
        generated += 1
      end
      puts "#{index}/#{total}" if (index % 100).zero?
    rescue => e
      failed += 1
      puts "❌ Photo #{photo.id} : #{e.class} #{e.message}"
    end

    puts "✅ #{generated} variante(s) générée(s), #{failed} échec(s) sur #{total} photo(s)."
  end

  # Avant la correction de Photo#lightbox_variant, la lightbox était générée avec
  # `resize_to_limit: nil` : une copie non redimensionnée de l'original.
  desc "Supprime les anciennes lightbox non redimensionnées (DRY-RUN par défaut, CONFIRM=1 pour supprimer)"
  task purge_obsolete_lightboxes: :environment do
    confirm = ENV["CONFIRM"] == "1"
    count = 0
    bytes = 0

    Photo.includes(image_attachment: :blob).find_each do |photo|
      next unless photo.image.attached?

      obsolete = photo.image.variant(resize_to_limit: nil)
      record = photo.image.blob.variant_records.find_by(variation_digest: obsolete.variation.digest)
      next unless record

      count += 1
      bytes += record.image.blob.byte_size if record.image.attached?
      next unless confirm

      record.image.purge
      record.destroy!
    end

    size_mb = (bytes.to_f / 1.megabyte).round(1)
    if confirm
      puts "🗑️  #{count} ancienne(s) lightbox supprimée(s) (#{size_mb} Mo libérés)."
    else
      puts "DRY-RUN : #{count} ancienne(s) lightbox à supprimer (#{size_mb} Mo). Relancer avec CONFIRM=1 pour supprimer."
    end
  end

  # Blobs qui ne sont plus rattachés à rien (ex. un original remplacé par sa version webp
  # dont la purge a échoué). On garde ceux de moins d'un jour : un upload peut être en cours.
  desc "Supprime les fichiers Active Storage rattachés à aucun enregistrement (DRY-RUN par défaut, CONFIRM=1 pour supprimer)"
  task purge_unattached_blobs: :environment do
    confirm = ENV["CONFIRM"] == "1"
    blobs = PurgeUnattachedBlobsJob.candidates
    count = blobs.count
    size_mb = (blobs.sum(:byte_size).to_f / 1.megabyte).round(1)

    if confirm
      PurgeUnattachedBlobsJob.perform_now
      puts "🗑️  #{count} blob(s) non rattaché(s) supprimé(s) (#{size_mb} Mo libérés)."
    else
      puts "DRY-RUN : #{count} blob(s) non rattaché(s) à supprimer (#{size_mb} Mo). Relancer avec CONFIRM=1 pour supprimer."
    end
  end

  # Fichiers présents sur le disque mais inconnus de la base (ex. purge interrompue).
  # Seuls les fichiers rangés comme Active Storage les range (ab/cd/abcd...) sont examinés :
  # les bases SQLite à la racine du dossier storage ne sont jamais touchées.
  desc "Supprime du disque les fichiers sans blob en base (DRY-RUN par défaut, CONFIRM=1 pour supprimer)"
  task purge_orphan_files: :environment do
    confirm = ENV["CONFIRM"] == "1"
    service = ActiveStorage::Blob.service
    abort "❌ Service #{service.class} non supporté : seul le stockage sur disque est géré." unless service.is_a?(ActiveStorage::Service::DiskService)

    files = Dir.glob(File.join(service.root, "??", "??", "*")).select do |path|
      key = File.basename(path)
      File.file?(path) && path == service.path_for(key)
    end

    orphans = files.each_slice(1000).flat_map do |batch|
      keys = batch.map { |path| File.basename(path) }
      known = ActiveStorage::Blob.where(key: keys).pluck(:key)
      batch.reject { |path| known.include?(File.basename(path)) }
    end
    size_mb = (orphans.sum { |path| File.size(path) }.to_f / 1.megabyte).round(1)

    if confirm
      orphans.each { |path| File.delete(path) }
      Dir.glob(File.join(service.root, "??", "??")).each { |dir| Dir.rmdir(dir) if File.directory?(dir) && Dir.empty?(dir) }
      Dir.glob(File.join(service.root, "??")).each { |dir| Dir.rmdir(dir) if File.directory?(dir) && Dir.empty?(dir) }
      puts "🗑️  #{orphans.size} fichier(s) orphelin(s) supprimé(s) sur #{files.size} (#{size_mb} Mo libérés)."
    else
      orphans.first(20).each { |path| puts "  #{path}" }
      puts "  ..." if orphans.size > 20
      puts "DRY-RUN : #{orphans.size} fichier(s) orphelin(s) sur #{files.size} (#{size_mb} Mo). Relancer avec CONFIRM=1 pour supprimer."
    end
  end
end
