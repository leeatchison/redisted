require 'spec_helper'

describe "Unique Index" do
  it "requires a unique index to have a unique value" do
    class IndexTest1 < Redisted::Base
      field :field1, type: :string
      field :field2, type: :string
      field :name, type: :string
      index :name, unique: true
    end
    a=IndexTest1.create({name: "Test"})
    b=IndexTest1.create
    lambda{
      b.name="Test"
    }.should raise_error
  end
  it "requires a unique index to have a unique value (alternate syntax)" do
    class IndexTest2 < Redisted::Base
      field :field1, type: :string
      field :field2, type: :string
      field :name, type: :string
      index :idxname, unique: :name
    end
    a=IndexTest2.create({name: "Test"})
    b=IndexTest2.create
    lambda{
      b.name="Test"
    }.should raise_error
  end
  it "allows changing a unique index value to a free value, and make the old value free again" do
    class IndexTest3 < Redisted::Base
      field :field1, type: :string
      field :field2, type: :string
      field :name, type: :string
      index :name, unique: true
    end
    a=IndexTest3.create({name: "Test"})
    b=IndexTest3.create
    lambda{
      b.name="Test"
    }.should raise_error
    a.name="Test2"
    lambda{
      b.name="Test"
    }.should_not raise_error
    lambda{
      a.name="Test"
    }.should raise_error
  end
  it "doesn't allow changing a unique index value to a value already in use" do
    class IndexTest4 < Redisted::Base
      field :field1, type: :string
      field :field2, type: :string
      field :name, type: :string
      index :name, unique: name
    end
    a=IndexTest4.create({name: "Test"})
    b=IndexTest4.create({name: "Test2"})
    lambda{
      b.name="Test"
    }.should raise_error
  end
  it "deletes the unique entry when an object is deleted" do
    class IndexTest5 < Redisted::Base
      field :field1, type: :string
      field :field2, type: :string
      field :name, type: :string
      index :name, unique: true
    end
    a=IndexTest5.create({name: "Test"})
    b=IndexTest5.create({name: "Test2"})
    lambda{
      b.name="Test"
    }.should raise_error
    a.delete
    lambda{
      b.name="Test"
    }.should_not raise_error
  end
  it "allows an index to be an array of fields" do
    class IndexTest6 < Redisted::Base
      field :field1, type: :string
      field :field2, type: :string
      field :name, type: :string
      index :special, unique: [:field1,:field2]
    end
    a=IndexTest6.create({field1: "test1",field2: "test2"})
    b=IndexTest6.create({field1: "test1",field2: "test3"})
    lambda{
      b.field1="test2"
    }.should_not raise_error
    lambda{
      b.field1="test2"
    }.should_not raise_error
    lambda{
      b.field1="test1"
    }.should raise_error
  end
  it "disallows two indexes to have the same name" do
    lambda{
      class IndexTest7 < Redisted::Base
        field :field1, type: :string
        field :field2, type: :string
        field :name, type: :string
        index :special, unique: [:field1,:field2]
        index :special, unique: [:field1,:name]
      end
    }.should raise_error
  end



end
