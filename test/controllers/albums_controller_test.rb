require "test_helper"

class AlbumsControllerTest < ActionDispatch::IntegrationTest
  test "root redirects to the owner's albums" do
    get root_url
    assert_redirected_to "/LsQnlt"
  end

  test "index lists only the user's published albums" do
    get user_albums_url(pseudonym: "alice")
    assert_response :success
    assert_includes response.body, albums(:alice_public).title
    assert_not_includes response.body, albums(:alice_draft).title
    assert_not_includes response.body, albums(:bob_public).title
  end

  test "index returns 404 for an unknown pseudonym" do
    get user_albums_url(pseudonym: "inconnu")
    assert_response :not_found
  end

  test "shows a public album" do
    get user_album_url(albums(:alice_public), pseudonym: "alice")
    assert_response :success
    assert_includes response.body, albums(:alice_public).title
  end

  test "protected album redirects to the password page" do
    album = albums(:alice_protected)
    get user_album_url(album, pseudonym: "alice")
    assert_redirected_to verify_password_user_album_path(album, pseudonym: "alice")
  end

  test "wrong password is refused" do
    album = albums(:alice_protected)
    post verify_password_user_album_url(album, pseudonym: "alice"), params: { password: "wrong" }
    assert_response :unprocessable_entity

    get user_album_url(album, pseudonym: "alice")
    assert_redirected_to verify_password_user_album_path(album, pseudonym: "alice")
  end

  test "right password unlocks the album for the session" do
    album = albums(:alice_protected)
    post verify_password_user_album_url(album, pseudonym: "alice"), params: { password: "secret123" }
    assert_redirected_to user_album_path(album, pseudonym: "alice")

    get user_album_url(album, pseudonym: "alice")
    assert_response :success
  end
end
