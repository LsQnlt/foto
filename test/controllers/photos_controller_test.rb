require "test_helper"

class PhotosControllerTest < ActionDispatch::IntegrationTest
  test "like increments the counter once per session" do
    photo = photos(:alice_public_photo)

    assert_difference -> { photo.reload.likes_count }, 1 do
      post like_photo_url(photo)
    end
    assert_response :success
    assert_equal({ "likes_count" => 1, "liked" => true }, response.parsed_body)

    assert_no_difference -> { photo.reload.likes_count } do
      post like_photo_url(photo)
    end
    assert_response :unprocessable_entity
  end

  test "track_view responds ok without authentication" do
    post track_view_photo_url(photos(:alice_public_photo))
    assert_response :success
  end
end
