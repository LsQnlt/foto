require "test_helper"

class PurgeUnattachedBlobsJobTest < ActiveJob::TestCase
  test "purges unattached blobs older than a day and keeps the rest" do
    old = ActiveStorage::Blob.create_and_upload!(io: file_fixture("photo.jpg").open, filename: "old.jpg")
    old.update_column(:created_at, 2.days.ago)
    recent = ActiveStorage::Blob.create_and_upload!(io: file_fixture("photo.jpg").open, filename: "recent.jpg")
    attached = photos(:alice_public_photo).image.blob

    PurgeUnattachedBlobsJob.perform_now

    assert_not ActiveStorage::Blob.exists?(old.id)
    assert ActiveStorage::Blob.exists?(recent.id)
    assert ActiveStorage::Blob.exists?(attached.id)
  end

  test "is scheduled daily in production" do
    config = YAML.load_file(Rails.root.join("config/recurring.yml"))
    assert_equal "PurgeUnattachedBlobsJob", config.dig("production", "purge_unattached_blobs", "class")
  end
end
