require 'test_helper'

class RoleTypesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:role_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create role_type" do
    assert_difference('RoleType.count') do
      post :create, :role_type => { }
    end

    assert_redirected_to role_type_path(assigns(:role_type))
  end

  test "should show role_type" do
    get :show, :id => role_types(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => role_types(:one).to_param
    assert_response :success
  end

  test "should update role_type" do
    put :update, :id => role_types(:one).to_param, :role_type => { }
    assert_redirected_to role_type_path(assigns(:role_type))
  end

  test "should destroy role_type" do
    assert_difference('RoleType.count', -1) do
      delete :destroy, :id => role_types(:one).to_param
    end

    assert_redirected_to role_types_path
  end
end
