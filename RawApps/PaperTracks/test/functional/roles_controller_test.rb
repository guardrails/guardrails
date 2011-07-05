require 'test_helper'

class RolesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:roles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create role" do
    assert_difference('Role.count') do
      post :create, :role => { }
    end

    assert_redirected_to role_path(assigns(:role))
  end

  test "should show role" do
    get :show, :id => roles(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => roles(:one).to_param
    assert_response :success
  end

  test "should update role" do
    put :update, :id => roles(:one).to_param, :role => { }
    assert_redirected_to role_path(assigns(:role))
  end

  test "should destroy role" do
    assert_difference('Role.count', -1) do
      delete :destroy, :id => roles(:one).to_param
    end

    assert_redirected_to roles_path
  end
end
