require "test_helper"

class PhotoTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "requires an image" do
    assert_not Photo.new(album: albums(:alice_public)).valid?
  end

  test "accepts a jpeg image" do
    photo = Photo.new(album: albums(:alice_public), image: fixture_file_upload("photo.jpg", "image/jpeg"))
    assert photo.valid?, photo.errors.full_messages.to_sentence
  end

  test "rejects a file that is not an image" do
    photo = Photo.new(album: albums(:alice_public), image: fixture_file_upload("not_an_image.txt", "text/plain"))
    assert_not photo.valid?
  end

  test "enqueues the optimization job after creation" do
    assert_enqueued_with(job: OptimizePhotoJob) do
      Photo.create!(album: albums(:alice_public), image: fixture_file_upload("photo.jpg", "image/jpeg"))
    end
  end

  test "thumb variant uses the thumb size" do
    photo = photos(:alice_public_photo)
    assert_equal({ resize_to_fill: [400, 300] }, photo.thumb_variant(method: :resize_to_fill).variation.transformations.except(:format))
  end

  test "lightbox variant uses the lightbox size" do
    photo = photos(:alice_public_photo)
    assert_equal({ resize_to_limit: [1800, 1350] }, photo.lightbox_variant.variation.transformations.except(:format))
  end
end
