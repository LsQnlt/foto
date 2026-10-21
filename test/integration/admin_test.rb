require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  test "admin requires authentication" do
    get admin_root_url
    assert_redirected_to new_session_url
  end

  test "every admin page renders for an admin" do
    sign_in_as users(:admin)

    [admin_root_url, admin_albums_url, admin_photos_url, admin_users_url, new_admin_album_url].each do |url|
      get url
      assert_response :success, "#{url} a répondu #{response.status}"
    end

    get admin_album_url(albums(:bob_public))
    assert_response :success
    get edit_admin_album_url(albums(:bob_public))
    assert_response :success
    get admin_photo_url(photos(:bob_public_photo))
    assert_response :success
  end

  test "admin sees every album" do
    sign_in_as users(:admin)
    get admin_albums_url
    assert_includes response.body, albums(:alice_public).title
    assert_includes response.body, albums(:bob_public).title
  end

  test "a user only sees their own albums" do
    sign_in_as users(:alice)
    get admin_albums_url
    assert_response :success
    assert_includes response.body, albums(:alice_public).title
    assert_not_includes response.body, albums(:bob_public).title
  end

  test "a user cannot open another user's album" do
    sign_in_as users(:alice)
    get admin_album_url(albums(:bob_public))
    assert_response :not_found
  end

  test "a user cannot create users" do
    sign_in_as users(:alice)
    get new_admin_user_url
    assert_redirected_to admin_users_path
  end

  test "creating an album with photos attaches them to the current user" do
    sign_in_as users(:alice)

    assert_difference -> { users(:alice).albums.count } => 1, -> { Photo.count } => 1 do
      post admin_albums_url, params: {
        album: {
          title: "Nouvel album",
          description: "Créé depuis l'admin",
          published: "1",
          password_protected: "0",
          uploaded_photos: [fixture_file_upload("photo.jpg", "image/jpeg")],
        },
      }
    end

    album = Album.find_by!(title: "Nouvel album")
    assert_redirected_to admin_album_path(album)
    assert_nil album.password_digest
  end

  test "updating an album can add a password" do
    sign_in_as users(:alice)
    album = albums(:alice_public)

    patch admin_album_url(album), params: { album: { password_protected: "1", password: "nouveau123" } }

    assert_redirected_to admin_album_path(album)
    assert album.reload.authenticate("nouveau123")
  end

  test "deleting a photo from an album" do
    sign_in_as users(:alice)
    photo = photos(:alice_public_photo)

    assert_difference("Photo.count", -1) do
      delete delete_photo_admin_album_url(photo.album, photo_id: photo.id)
    end
  end

  # Sécurité : un utilisateur ne doit jamais pouvoir agir sur les données d'un autre

  test "a user cannot delete another user's photo" do
    sign_in_as users(:alice)
    photo = photos(:bob_public_photo)

    assert_no_difference("Photo.count") do
      delete delete_photo_admin_album_url(photo.album, photo_id: photo.id)
    end
    assert_response :not_found

    assert_no_difference("Photo.count") do
      delete delete_photo_admin_album_url(albums(:alice_public), photo_id: photo.id)
    end
  end

  test "a user cannot create an album for another user" do
    sign_in_as users(:alice)

    post admin_albums_url, params: { album: { title: "Usurpation", password_protected: "0", user_id: users(:bob).id } }

    assert_equal users(:alice), Album.find_by!(title: "Usurpation").user
  end

  test "a user cannot give their album to another user" do
    sign_in_as users(:alice)
    album = albums(:alice_public)

    patch admin_album_url(album), params: { album: { title: "Renommé", user_id: users(:bob).id } }

    album.reload
    assert_equal "Renommé", album.title
    assert_equal users(:alice), album.user
  end

  test "an admin can assign an album to another user" do
    sign_in_as users(:admin)
    album = albums(:alice_public)

    patch admin_album_url(album), params: { album: { user_id: users(:bob).id } }

    assert_equal users(:bob), album.reload.user
  end

  test "a user cannot add a photo to another user's album" do
    sign_in_as users(:alice)

    assert_no_difference("Photo.count") do
      post admin_photos_url, params: { photo: { album_id: albums(:bob_public).id, image: fixture_file_upload("photo.jpg", "image/jpeg") } }
    end
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "a user cannot move their photo into another user's album" do
    sign_in_as users(:alice)
    photo = photos(:alice_public_photo)

    patch admin_photo_url(photo), params: { photo: { album_id: albums(:bob_public).id } }

    assert_equal albums(:alice_public), photo.reload.album
  end

  test "a user can add a photo to their own album" do
    sign_in_as users(:alice)

    assert_difference("Photo.count", 1) do
      post admin_photos_url, params: { photo: { album_id: albums(:alice_public).id, image: fixture_file_upload("photo.jpg", "image/jpeg") } }
    end
  end
end
