require 'spec_helper'

describe "Scopes" do
  it "can be created" do
    class Scope1 < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer
      index :odd, includes: ->(elem){(elem.test_int%2)!=0}
      index :even, includes: ->(elem){(elem.test_int%2)==0}
      index :thrice, includes: ->(elem){(elem.test_int%3)==0}
      index :asc, order: ->(elem){elem.test_int},fields: :test_int
      index :desc, order: ->(elem){-elem.test_int},fields: :test_int

      scope :oddasc,->{by_odd.by_asc}
      scope :evenasc,->{by_even.by_asc}
      scope :oddthrice,->{by_thrice.by_odd}
    end
    a=Scope1.create({test_int: 3})
    b=Scope1.create({test_int: 4})
    c=Scope1.create({test_int: 2})
    d=Scope1.create({test_int: 9})
    e=Scope1.create({test_int: 1})
    f=Scope1.create({test_int: 6})

    res=Scope1.oddasc.all
    res.size.should ==3
    res[0].id.to_i.should ==e.id
    res[1].id.to_i.should ==a.id
    res[2].id.to_i.should ==d.id

    res=Scope1.evenasc.all
    res.size.should ==3
    res[0].id.to_i.should ==c.id
    res[1].id.to_i.should ==b.id
    res[2].id.to_i.should ==f.id

    res=Scope1.oddthrice.by_asc.all
    res.size.should ==2
    res[0].id.to_i.should ==a.id
    res[1].id.to_i.should ==d.id
    res=Scope1.oddthrice.by_desc.all
    res.size.should ==2
    res[0].id.to_i.should ==d.id
    res[1].id.to_i.should ==a.id
  end
  it "allows incomplete filters to work" do
    class Scope2 < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer
      index :odd, includes: ->(elem){(elem.test_int%2)!=0}
      index :even, includes: ->(elem){(elem.test_int%2)==0}
      index :thrice, includes: ->(elem){(elem.test_int%3)==0}
      index :asc, order: ->(elem){elem.test_int},fields: :test_int
      index :desc, order: ->(elem){-elem.test_int},fields: :test_int

      scope :oddasc,->{by_odd.by_asc}
      scope :evenasc,->{by_even.by_asc}
      scope :thriceasc,->{by_thrice.by_asc}
      scope :thriceevenasc,->{by_thrice.by_even.by_asc}
    end
    a=Scope2.create({test_int: 3})
    b=Scope2.create({test_int: 4})
    c=Scope2.create({test_int: 2})
    d=Scope2.create({test_int: 9})
    e=Scope2.create({test_int: 1})
    f=Scope2.create({test_int: 6})

    aaa=Scope2.oddasc
    res=aaa.all
    res.size.should ==3
    res[0].id.to_i.should ==e.id
    res[1].id.to_i.should ==a.id
    res[2].id.to_i.should ==d.id

    aaa=Scope2.scoped
    res=aaa.thriceasc.all
    res.size.should ==3
    res[0].id.to_i.should ==a.id
    res[1].id.to_i.should ==f.id
    res[2].id.to_i.should ==d.id

    aaa=Scope2.thriceevenasc
    res=aaa.all
    res.size.should ==1
    res[0].id.to_i.should ==f.id

  end
end
