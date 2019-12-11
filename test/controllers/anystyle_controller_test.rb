require 'test_helper'

class AnystyleControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
    assert_select 'body[ng-app]', 1
  end
end
