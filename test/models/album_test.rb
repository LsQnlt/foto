require "test_helper"

class AlbumTest < ActiveSupport::TestCase
  test "published scope only returns published albums" do
    assert_includes Album.published, albums(:alice_public)
    assert_not_includes Album.published, albums(:alice_draft)
  end

  test "requires a password when password protected" do
    album = Album.new(title: "Secret", user: users(:alice), password_protected: true)
    assert_not album.valid?
    album.password = "secret123"
    assert album.valid?
  end

  test "authenticates with its password" do
    album = albums(:alice_protected)
    assert album.authenticate("secret123")
    assert_not album.authenticate("wrong")
  end

  test "cover photo is the oldest photo" do
    album = albums(:alice_public)
    newer = album.photos.create!(image: fixture_file_upload("photo2.jpg", "image/jpeg"), created_at: 1.day.from_now)
    assert_equal photos(:alice_public_photo), album.cover_photo
    assert_not_equal newer, album.cover_photo
  end

  test "destroying an album destroys its photos" do
    assert_difference("Photo.count", -1) do
      albums(:alice_public).destroy
    end
  end
end
