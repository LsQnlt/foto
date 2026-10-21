require "test_helper"
require "rake"
require "minitest/mock"

class PhotosTasksTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    unless Rake::Task.task_defined?("photos:generate_variants")
      Rake::Task.define_task(:environment)
      load Rails.root.join("lib/tasks/photos.rake")
    end
    # Les photos des fixtures n'ont pas de fichier sur le disque : on ne garde qu'une vraie photo
    Photo.delete_all
    @photo = Photo.create!(album: albums(:alice_public), image: fixture_file_upload("photo.jpg", "image/jpeg"))
  end

  test "generate_variants creates the thumb and lightbox variants once" do
    output, = capture_io { Rake::Task["photos:generate_variants"].execute }
    assert_includes output, "2 variante(s) générée(s), 0 échec(s)"
    assert_equal 2, @photo.image.blob.variant_records.count

    output, = capture_io { Rake::Task["photos:generate_variants"].execute }
    assert_includes output, "0 variante(s) générée(s)"
  end

  test "purge_obsolete_lightboxes only deletes the unresized lightbox, and only with CONFIRM=1" do
    @photo.image.variant(resize_to_limit: nil).processed
    @photo.lightbox_variant.processed
    blob = @photo.image.blob

    output, = capture_io { Rake::Task["photos:purge_obsolete_lightboxes"].execute }
    assert_includes output, "DRY-RUN : 1 ancienne(s) lightbox"
    assert_equal 2, blob.variant_records.count

    ENV["CONFIRM"] = "1"
    output, = capture_io { Rake::Task["photos:purge_obsolete_lightboxes"].execute }
    assert_includes output, "1 ancienne(s) lightbox supprimée(s)"
    assert_equal [@photo.lightbox_variant.variation.digest], blob.variant_records.reload.pluck(:variation_digest)
  ensure
    ENV.delete("CONFIRM")
  end

  test "purge_unattached_blobs only deletes old unattached blobs, and only with CONFIRM=1" do
    old = ActiveStorage::Blob.create_and_upload!(io: file_fixture("photo.jpg").open, filename: "old.jpg")
    old.update_column(:created_at, 2.days.ago)
    recent = ActiveStorage::Blob.create_and_upload!(io: file_fixture("photo.jpg").open, filename: "recent.jpg")

    output, = capture_io { Rake::Task["photos:purge_unattached_blobs"].execute }
    assert_includes output, "DRY-RUN : 1 blob(s)"
    assert ActiveStorage::Blob.exists?(old.id)

    ENV["CONFIRM"] = "1"
    capture_io { Rake::Task["photos:purge_unattached_blobs"].execute }
    assert_not ActiveStorage::Blob.exists?(old.id)
    assert ActiveStorage::Blob.exists?(recent.id)
    assert ActiveStorage::Blob.exists?(@photo.image.blob.id)
  ensure
    ENV.delete("CONFIRM")
  end

  test "purge_orphan_files only deletes files unknown to the database" do
    Dir.mktmpdir do |root|
      service = ActiveStorage::Service::DiskService.new(root: root)
      known = @photo.image.blob.key
      orphan = ActiveStorage::Blob.generate_unique_secure_token(length: ActiveStorage::Blob::MINIMUM_TOKEN_LENGTH)
      [known, orphan].each do |key|
        FileUtils.mkdir_p(File.dirname(service.path_for(key)))
        File.write(service.path_for(key), "data")
      end
      File.write(File.join(root, "production.sqlite3"), "db")

      ActiveStorage::Blob.stub(:service, service) do
        output, = capture_io { Rake::Task["photos:purge_orphan_files"].execute }
        assert_includes output, "DRY-RUN : 1 fichier(s) orphelin(s) sur 2"
        assert File.exist?(service.path_for(orphan))

        ENV["CONFIRM"] = "1"
        capture_io { Rake::Task["photos:purge_orphan_files"].execute }
      end

      assert_not File.exist?(service.path_for(orphan))
      assert_not Dir.exist?(File.join(root, orphan[0..1], orphan[2..3]))
      assert File.exist?(service.path_for(known))
      assert File.exist?(File.join(root, "production.sqlite3"))
    end
  ensure
    ENV.delete("CONFIRM")
  end
end
