require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  test "should get all" do
    get :all
    assert_response :success
  end

  test "should get by_room" do
    get :by_room
    assert_response :success
  end

end
