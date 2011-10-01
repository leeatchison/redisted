require 'spec_helper'

describe "Validations" do
  it "can specify the maximum length of a field" do
    class Validate1 < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer
      field :provider, type: :string

      validates_length_of :provider, :maximum=>20
    end
    a=Validate1.create({provider: "TestVal"})
    a.provider="Test2Val"
    lambda{
      a.provider="This is too long...This is too long..."
    }.should raise_error
    a.provider="Test3Val"
  end
  it "can specify the minimum length of a field" do
    class Validate2 < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer
      field :provider, type: :string

      validates_length_of :provider, :minimum=>5
    end
    a=Validate1.create({provider: "TestVal"})
    a.provider="Test2Val"
    lambda{
      a.provider="shrt"
    }.should raise_error
    a.provider="Test3Val"
  end
  it "works with a deferred save" do
    class Validate1 < Redisted::Base
      always_cache_until_save
      field :name, type: :string
      field :test_int, type: :integer
      field :provider, type: :string

      validates_length_of :provider, :maximum=>20
    end
    a=Validate1.create({provider: "TestVal"})
    a.provider="Test2Val"
    a.save
    a.provider="This is too long...This is too long..."
    lambda{
      a.save
    }.should raise_error
    a.provider="Test3Val"
    a.save
  end
  it "can make sure a field is unique", :broken do
    class Validate3 < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer
      field :provider, type: :string

      validates_uniqueness_of :name
    end
    a=Validate1.create({name: "Test1"})
    b=Validate1.create
    b.name="Test2"
    lambda{
      b.name="Test1"
    }.should raise_error
    b.name="Test2"
    a.name="Test3"
    b.name="Test1"
  end
end
