require 'test_helper'

class PermissionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:permissions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create permission" do
    assert_difference('Permission.count') do
      post :create, :permission => { }
    end

    assert_redirected_to permission_path(assigns(:permission))
  end

  test "should show permission" do
    get :show, :id => permissions(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => permissions(:one).to_param
    assert_response :success
  end

  test "should update permission" do
    put :update, :id => permissions(:one).to_param, :permission => { }
    assert_redirected_to permission_path(assigns(:permission))
  end

  test "should destroy permission" do
    assert_difference('Permission.count', -1) do
      delete :destroy, :id => permissions(:one).to_param
    end

    assert_redirected_to permissions_path
  end
end
