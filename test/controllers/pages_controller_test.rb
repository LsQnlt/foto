require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get a_propos" do
    get pages_a_propos_url
    assert_response :success
  end

  test "should get contact" do
    get pages_contact_url
    assert_response :success
  end

  test "health check is up" do
    get rails_health_check_url
    assert_response :success
  end
end
