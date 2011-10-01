require 'spec_helper'

describe "Find" do
  class FieldTest < Redisted::Base
    field :field1, type: :string
    field :field2, type: :string
    field :field3, type: :string
  end
  it "can find an object with a specific ID" do
    orig=FieldTest.create({field1: "test1123", field2: "test1223"})
    id=orig.id
    obj=FieldTest.find id
    obj.field1.should =="test1123"
    obj.field2.should =="test1223"
    orig.id.should ==obj.id
    orig.object_id.should_not ==obj.object_id
  end
  it "can find an array objects with a list of IDs" do
    orig1=FieldTest.create({field1: "test1123", field2: "test1223"})
    orig2=FieldTest.create({field1: "test2123", field2: "test2223"})
    orig3=FieldTest.create({field1: "test3123", field2: "test3223"})
    objs=FieldTest.find [orig1.id,orig3.id,orig2.id]
    objs[0].field1="test1123"
    objs[0].field2="test1223"
    objs[2].field1="test2123"
    objs[2].field2="test2223"
    objs[1].field1="test3123"
    objs[1].field2="test3223"
  end
end
