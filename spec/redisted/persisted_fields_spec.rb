require 'spec_helper'

describe "Persisted Fields" do
  class FieldTest1 < Redisted::Base
    field :field1, type: :string
    field :field2, type: :string
    field :field3, type: :string
  end
  it "can be saved one value at a time" do
    a=FieldTest1.create
    key="field_test1:#{a.id}"
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
    a.field1="test"
    $redis.hget(key,"field1").should =="test"
    $redis.hget(key,"field2").should be_nil
    a.field2="test2"
    $redis.hget(key,"field1").should =="test"
    $redis.hget(key,"field2").should =="test2"
    a.save
    $redis.hget(key,"field1").should =="test"
    $redis.hget(key,"field2").should =="test2"
  end
  it "can be cached and save them all in one redis call" do
    a=FieldTest1.create
    key="field_test1:#{a.id}"
    a.cache do
      $redis.hget(key,"field1").should be_nil
      $redis.hget(key,"field2").should be_nil
      a.field1="test"
      $redis.hget(key,"field1").should be_nil
      $redis.hget(key,"field2").should be_nil
      a.field2="test2"
      $redis.hget(key,"field1").should be_nil
      $redis.hget(key,"field2").should be_nil
    end
    $redis.hget(key,"field1").should =="test"
    $redis.hget(key,"field2").should =="test2"
  end
  it "can be cached and save them all in one redis call without using a block" do
    a=FieldTest1.create
    key="field_test1:#{a.id}"
    a.cache
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
    a.field1="test"
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
    a.field2="test2"
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
    a.save
    $redis.hget(key,"field1").should =="test"
    $redis.hget(key,"field2").should =="test2"
  end
  it "caches until first save" do
    a=FieldTest1.new
    a.field1="Test"
    a.field2="Test2"
    key="field_test1:#{a.id}"
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
    a.save
    key="field_test1:#{a.id}"
    $redis.hget(key,"field1").should =="Test"
    $redis.hget(key,"field2").should =="Test2"
  end
  it "can be configured to cache all until save" do
    class FieldTest < Redisted::Base
      always_cache_until_save
      field :field1, type: :string
      field :field2, type: :string
    end
    a=FieldTest.create
    key="field_test:#{a.id}"
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
    a.field1="test"
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
    a.field2="test2"
    $redis.hget(key,"field1").should be_nil
    $redis.hget(key,"field2").should be_nil
    a.save
    $redis.hget(key,"field1").should =="test"
    $redis.hget(key,"field2").should =="test2"
  end
  it "can be read one by one as needed" do
    key="field_test1:12345"
    $redis.hmset key,"field1","3","field2","4"
    b=FieldTest1.find(12345)
    b.field1.should =="3"
    $redis.hmset key,"field1","5","field2","6"
    b.field2.should =="6"
  end
  it "can have the cache flushed" do
    key="field_test1:12345"
    $redis.hmset key,"field1","3","field2","4"
    b=FieldTest1.find(12345)
    b.field1.should =="3"
    $redis.hmset key,"field1","5","field2","6"
    b.field1.should =="3"
    b.field2.should =="6"
    b.flush
    b.field1.should =="5"
    b.field2.should =="6"
  end
  it "are read only once then cached" do
    key="field_test1:12345"
    $redis.hmset key,"field1","3"
    b=FieldTest1.find(12345)
    b.field1.should =="3"
    $redis.hmset key,"field1","5"
    b.field1.should =="3"
  end
  it "can be read and cached all at once (at load)" do
    class FieldTest < Redisted::Base
      pre_cache_all
      field :field1, type: :string
      field :field2, type: :string
      field :field3, type: :string
    end
    key="field_test:12345"
    $redis.hmset key,"field1","3","field2","4","field3","5"
    b=FieldTest.find(12345)
    $redis.hmset key,"field1","6","field2","7","field3","8"
    b.field1.should =="3"
    b.field2.should =="4"
    b.field3.should =="5"
    b.flush
    b.field1.should =="6"
    b.field2.should =="7"
    b.field3.should =="8"
  end
  it "can be automatically read and cached at object creation" do
    class FieldTest < Redisted::Base
      pre_cache_all when: :create
      field :field1, type: :string
      field :field2, type: :string
      field :field3, type: :string
    end
    key="field_test:12345"
    $redis.hmset key,"field1","3","field2","4","field3","5"
    b=FieldTest.find(12345)
    $redis.hmset key,"field1","6","field2","7","field3","8"
    b.field1.should =="3"
    b.field2.should =="4"
    b.field3.should =="5"
    b.flush
    b.field1.should =="6"
    b.field2.should =="7"
    b.field3.should =="8"
  end
  it "can be automatically read and cached at first field read" do
    class FieldTest < Redisted::Base
      pre_cache_all when: :first_read
      field :field1, type: :string
      field :field2, type: :string
      field :field3, type: :string
    end
    key="field_test:12345"
    $redis.hmset key,"field1","3","field2","4","field3","5"
    b=FieldTest.find(12345)
    $redis.hmset key,"field1","6","field2","7","field3","8"
    b.field1.should =="6"
    $redis.hmset key,"field1","9","field2","10","field3","11"
    b.field2.should =="7"
    b.field3.should =="8"
    b.flush
    b.field1.should =="9"
    b.field2.should =="10"
    b.field3.should =="11"
  end
  it "can have autoamtic caching explicitely for all fields" do
    class FieldTest < Redisted::Base
      pre_cache_all when: :create, keys: :all
      field :field1, type: :string
      field :field2, type: :string
      field :field3, type: :string
    end
    key="field_test:12345"
    $redis.hmset key,"field1","3","field2","4","field3","5"
    b=FieldTest.find(12345)
    $redis.hmset key,"field1","6","field2","7","field3","8"
    b.field1.should =="3"
    b.field2.should =="4"
    b.field3.should =="5"
    b.flush
    b.field1.should =="6"
    b.field2.should =="7"
    b.field3.should =="8"
  end
  it "can have automatic caching for some fields only" do
    class FieldTest < Redisted::Base
      pre_cache_all when: :create, keys: [:field1,:field3]
      field :field1, type: :string
      field :field2, type: :string
      field :field3, type: :string
    end
    key="field_test:12345"
    $redis.hmset key,"field1","3","field2","4","field3","5"
    b=FieldTest.find(12345)
    $redis.hmset key,"field1","6","field2","7","field3","8"
    b.field1.should =="3"
    b.field2.should =="7"
    b.field3.should =="5"
    b.flush
    b.field1.should =="6"
    b.field2.should =="7"
    b.field3.should =="8"
  end
  it "can have automatic caching for all fields except specified fields" do
    class FieldTest < Redisted::Base
      pre_cache_all when: :create, except: [:field1,:field3]
      field :field1, type: :string
      field :field2, type: :string
      field :field3, type: :string
    end
    key="field_test:12345"
    $redis.hmset key,"field1","3","field2","4","field3","5"
    b=FieldTest.find(12345)
    $redis.hmset key,"field1","6","field2","7","field3","8"
    b.field1.should =="6"
    b.field2.should =="4"
    b.field3.should =="8"
    b.flush
    b.field1.should =="6"
    b.field2.should =="7"
    b.field3.should =="8"
  end

  it "can populate an object via parameters to create" do
    obj=FieldTest1.create({field1: "test111",field2: "test222"})
    key="field_test1:#{obj.id}"
    $redis.hget(key,"field1").should =="test111"
    $redis.hget(key,"field2").should =="test222"
  end
end
