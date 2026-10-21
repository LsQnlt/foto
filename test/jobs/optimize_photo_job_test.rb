require "test_helper"

class OptimizePhotoJobTest < ActiveJob::TestCase
  setup do
    require "vips"
  rescue LoadError
    skip "libvips n'est pas installé sur cette machine"
  end

  test "converts the original to webp and generates the variants" do
    photo = Photo.create!(album: albums(:alice_public), image: fixture_file_upload("photo.jpg", "image/jpeg"))

    OptimizePhotoJob.perform_now(photo.id)

    photo.reload
    assert_equal "image/webp", photo.image.content_type
    assert_equal "photo.webp", photo.image.filename.to_s
    assert photo.thumb_variant(method: :resize_to_fill).send(:processed?)
    assert photo.lightbox_variant(method: :resize_to_limit).send(:processed?)
  end

  test "ignores a photo that no longer exists" do
    assert_nothing_raised { OptimizePhotoJob.perform_now(-1) }
  end
end
