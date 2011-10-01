require 'spec_helper'

describe "Callbacks" do
  before :each do
    $create_called=false
    $update_called=false
    $save_called=false
    $destroy_called=false
  end
  class CallbackTest < Redisted::Base
    field :name, type: :string
    after_create :create_handler
    def create_handler
      $create_called=true
    end
    after_update do
      $update_called=true
    end
    after_save do
      $save_called=true
    end
    after_destroy :destroy_handler
    def destroy_handler
      $destroy_called=false
    end
  end
  it "work on create" do
    a=CallbackTest.new
    $create_called.should be_false
    a.save
    $create_called.should be_true
    $update_called.should be_false
  end
  it "work on update" do
    a=CallbackTest.new
    $create_called.should be_false
    $update_called.should be_false
    a.save
    $create_called.should be_true
    $update_called.should be_false
    a.name="Test"
    $create_called.should be_true
    $update_called.should be_true
  end
  it "work on save" do
    a=CallbackTest.create
    $save_called=false
    $save_called.should be_false
    a.name="Test"
    $save_called.should be_true
  end
  it "work on save (non-cached)" do
    a=CallbackTest.create
    $save_called=false
    $save_called.should be_false
    a.cache do
      a.name="Test"
      $save_called.should be_false
    end
    $save_called.should be_true
  end
  it "work on destroy" do
    a=CallbackTest.create
    $destroy_called=false
    $destroy_called.should be_false
    a.destroy
    $destroy_called.should be_true
  end
  it "not work on delete" do
    a=CallbackTest.create
    $destroy_called=false
    $destroy_called.should be_false
    a.delete
    $destroy_called.should be_false
  end
end
