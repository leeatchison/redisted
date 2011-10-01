require 'spec_helper'

describe "Delete/Destroy" do
  class FieldTest < Redisted::Base
    field :field1, type: :string
    field :field2, type: :string
    field :field3, type: :string
  end
  it "an object can be deleted" do
    a=FieldTest.create({field1: "test1123", field2: "test1223"})
    key="field_test:#{a.id}"
    $redis.hget(key,"field1").should ==("test1123")
    $redis.hget(key,"field2").should ==("test1223")
    a.delete
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
  end
  it "an object can be destroyed" do
    a=FieldTest.create({field1: "test1123", field2: "test1223"})
    key="field_test:#{a.id}"
    $redis.hget(key,"field1").should ==("test1123")
    $redis.hget(key,"field2").should ==("test1223")
    a.destroy
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
  end
  it "an object that was opened (not created) can be deleted" do
    orig=FieldTest.create({field1: "test1123", field2: "test1223"})
    a=FieldTest.find orig.id
    a.id.should ==orig.id
    key="field_test:#{a.id}"
    $redis.hget(key,"field1").should ==("test1123")
    $redis.hget(key,"field2").should ==("test1223")
    a.delete
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
  end
  it "an object that was opened (not created) can be destroyed" do
    orig=FieldTest.create({field1: "test1123", field2: "test1223"})
    a=FieldTest.find orig.id
    a.id.should ==orig.id
    key="field_test:#{a.id}"
    $redis.hget(key,"field1").should ==("test1123")
    $redis.hget(key,"field2").should ==("test1223")
    a.destroy
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
  end
end
