require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by the Rails when you ran the scaffold generator.

describe SettingsController do

  before(:each) do
    Setting[:provincial_alert] = "0"
    Setting[:admin_alert] = "1"
    Setting[:national_alert] = "1"
  end

  def mock_setting(stubs={})
    @mock_setting ||= mock_model(Setting, stubs).as_null_object
  end



  describe "GET alert_config from the setting" do
    it "should read admin_alert , provincial_alert, national_alert" do
      get :alert_config
      assigns[:provincial_alert].should == "0"
      assigns[:admin_alert].should == "1"
      assigns[:national_alert].should ==  "1"
    end
    
    it "should render alert_config" do
      get :alert_config
      response.should render_template :alert_config
    end
  end

  describe "update alert config" do
    before(:each) do
      @attributes = {
            :provincial_alert =>1,
            :national_alert => 0,
            :admin_alert => 1
      }
      @provincial_alert = 1
      @national_alert = 0
      @admin_alert = 1

      Setting.stub("[]=").with(:provincial_alert,1).and_return(@provincial_alert)
      Setting.stub("[]=").with(:national_alert,0).and_return(@national_alert)
      Setting.stub("[]=").with(:admin_alert,1).and_return(@admin_alert)
    end

    it "should set the configurations properly" do
      Setting.should_receive("[]=").with(:provincial_alert,1).and_return(@provincial_alert)
      Setting.should_receive("[]=").with(:national_alert,0).and_return(@national_alert)
      Setting.should_receive("[]=").with(:admin_alert,1).and_return(@admin_alert)

      post :update_alert_config , :setting => @attributes
    end

    it "should have flash with msg-notice key" do
      post :update_alert_config, :setting => @attributes
      flash["msg-notice"].should_not be_empty
    end

    it "should redirect to alert_config" do
      post :update_alert_config, :setting => @attributes
      response.should redirect_to :alert_config
    end
  end
end