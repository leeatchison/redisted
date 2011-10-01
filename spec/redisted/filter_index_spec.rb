
describe "Filter Index" do
  it "creates filter index" do
    class FilterIndex1 < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer
      index :odd, includes: ->(elem){(elem.test_int%2)!=0}
      index :even, includes: ->(elem){(elem.test_int%2)==0}
      index :thrice, includes: ->(elem){(elem.test_int%3)==0}
      index :asc, order: ->(elem){elem.test_int},fields: :test_int
      index :desc, order: ->(elem){-elem.test_int},fields: :test_int
    end
    a=FilterIndex1.create({test_int: 3})
    b=FilterIndex1.create({test_int: 4})
    c=FilterIndex1.create({test_int: 2})
    d=FilterIndex1.create({test_int: 9})
    e=FilterIndex1.create({test_int: 1})
    f=FilterIndex1.create({test_int: 6})

    res=FilterIndex1.by_odd.by_asc.all
    res.size.should ==3
    res[0].id.to_i.should ==e.id
    res[1].id.to_i.should ==a.id
    res[2].id.to_i.should ==d.id

    res=FilterIndex1.by_even.by_asc.all
    res.size.should ==3
    res[0].id.to_i.should ==c.id
    res[1].id.to_i.should ==b.id
    res[2].id.to_i.should ==f.id

    res=FilterIndex1.by_even.by_desc.all
    res.size.should ==3
    res[0].id.to_i.should ==f.id
    res[1].id.to_i.should ==b.id
    res[2].id.to_i.should ==c.id

    res=FilterIndex1.by_thrice.by_asc.all
    res.size.should ==3
    res[0].id.to_i.should ==a.id
    res[1].id.to_i.should ==f.id
    res[2].id.to_i.should ==d.id

    res=FilterIndex1.by_thrice.by_odd.by_asc.all
    res.size.should ==2
    res[0].id.to_i.should ==a.id
    res[1].id.to_i.should ==d.id

    res=FilterIndex1.by_thrice.by_even.by_asc.all
    res.size.should ==1
    res[0].id.to_i.should ==f.id
  end
  it "allows incomplete filters to work" do
    class FilterIndex2 < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer
      index :odd, includes: ->(elem){(elem.test_int%2)!=0}
      index :even, includes: ->(elem){(elem.test_int%2)==0}
      index :thrice, includes: ->(elem){(elem.test_int%3)==0}
      index :asc, order: ->(elem){elem.test_int},fields: :test_int
      index :desc, order: ->(elem){-elem.test_int},fields: :test_int
    end
    a=FilterIndex2.create({test_int: 3})
    b=FilterIndex2.create({test_int: 4})
    c=FilterIndex2.create({test_int: 2})
    d=FilterIndex2.create({test_int: 9})
    e=FilterIndex2.create({test_int: 1})
    f=FilterIndex2.create({test_int: 6})

    aaa=FilterIndex2.by_odd
    res=aaa.by_asc.all
    res.size.should ==3
    res[0].id.to_i.should ==e.id
    res[1].id.to_i.should ==a.id
    res[2].id.to_i.should ==d.id

    aaa=FilterIndex2.scoped
    res=aaa.by_thrice.by_asc.all
    res.size.should ==3
    res[0].id.to_i.should ==a.id
    res[1].id.to_i.should ==f.id
    res[2].id.to_i.should ==d.id

    aaa=FilterIndex2.by_thrice.by_even.by_asc
    res=aaa.all
    res.size.should ==1
    res[0].id.to_i.should ==f.id

  end
end
