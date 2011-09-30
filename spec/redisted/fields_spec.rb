require 'spec_helper'

describe "Fields" do
  class FieldTest1 < Redisted::Base
    field :field1, type: :string
    field :field2, type: :string
    field :field3, type: :string
  end
  class FieldTest2 < Redisted::Base
    field :field1, type: :string
    field :field2, type: :integer
    field :field3, type: :string
  end
  it "can be added to a model using new as separate statements" do

    a=FieldTest1.new
    a.save
    a.field1="test1"
    a.field2="test2"
    a.field3="test3"

    key="field_test1:#{a.id}"
    $redis.hget(key,"field1").should ==("test1")
    $redis.hget(key,"field2").should ==("test2")
    $redis.hget(key,"field3").should ==("test3")
  end
  it "can be added to a model using create as separate statements" do
    a=FieldTest1.create
    a.field1="test1"
    a.field2="test2"
    a.field3="test3"

    key="field_test1:#{a.id}"
    $redis.hget(key,"field1").should ==("test1")
    $redis.hget(key,"field2").should ==("test2")
    $redis.hget(key,"field3").should ==("test3")
  end
  it "can be added to a model using new as arguments" do
    a=FieldTest1.new({field1: "test1", field2: "test2", field3: "test3"})
    a.save

    key="field_test1:#{a.id}"
    $redis.hget(key,"field1").should ==("test1")
    $redis.hget(key,"field2").should ==("test2")
    $redis.hget(key,"field3").should ==("test3")
  end
  it "can be added to a model using create as arguments" do

    a=FieldTest1.create({field1: "test1", field2: "test2", field3: "test3"})

    key="field_test1:#{a.id}"
    $redis.hget(key,"field1").should ==("test1")
    $redis.hget(key,"field2").should ==("test2")
    $redis.hget(key,"field3").should ==("test3")
  end
  it "can be integers" do
    a=FieldTest2.create
    a.field2="456def"
    a.save
    a.field2.should ==456
    key="field_test2:#{a.id}"
    $redis.hget(key,"field2").should ==("456")
  end
  it "can be string" do
    a=FieldTest2.create
    a.field1="123abc"
    a.save
    a.field1.should =="123abc"
    key="field_test2:#{a.id}"
    $redis.hget(key,"field1").should ==("123abc")
  end
  it "can be datetime" do
    now=DateTime.now
    a=FieldTest2.create
    a.field3=now
    a.save
    a.field3.should ==now
    key="field_test2:#{a.id}"
    $redis.hget(key,"field3").should ==now.to_s
  end
  it "can have their configuration read from the model's Class" do
    field1_list=FieldTest1.fields
    field2_list=FieldTest2.fields

    field1_list[:field1].should_not be_nil
    field1_list[:field1][:type].should ==:string
    field1_list[:field2].should_not be_nil
    field1_list[:field2][:type].should ==:string
    field1_list[:field3].should_not be_nil
    field1_list[:field3][:type].should ==:string # datetime...
    field2_list[:field1].should_not be_nil
    field2_list[:field1][:type].should ==:string
    field2_list[:field2].should_not be_nil
    field2_list[:field2][:type].should ==:integer
    field2_list[:field3].should_not be_nil
    field2_list[:field3][:type].should ==:string

  end
  it "can have their configuration read from an instance of the model" do
    a1=FieldTest1.new
    a2=FieldTest2.new
    field1_list=a1.fields
    field2_list=a2.fields

    field1_list[:field1].should_not be_nil
    field1_list[:field1][:type].should ==:string
    field1_list[:field2].should_not be_nil
    field1_list[:field2][:type].should ==:string
    field1_list[:field3].should_not be_nil
    field1_list[:field3][:type].should ==:string # datetime...
    field2_list[:field1].should_not be_nil
    field2_list[:field1][:type].should ==:string
    field2_list[:field2].should_not be_nil
    field2_list[:field2][:type].should ==:integer
    field2_list[:field3].should_not be_nil
    field2_list[:field3][:type].should ==:string
  end
end
