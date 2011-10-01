
describe "Match Index" do
  it "creates match index" do
    class MatchIndex1 < Redisted::Base
      field :name, type: :string
      field :test_int, type: :string
      field :provider, type: :string

      index :provider, match: ->(elem){(elem.provider)}, fields: :provider,order: ->(elem){elem.test_int}
    end
    a=MatchIndex1.create({provider: "cable",test_int: 1})
    b=MatchIndex1.create({provider: "satellite",test_int: 2})
    c=MatchIndex1.create({provider: "cable",test_int: 3})
    d=MatchIndex1.create({provider: "overair",test_int: 4})
    e=MatchIndex1.create({provider: "satellite",test_int: 5})
    f=MatchIndex1.create({provider: "cable",test_int: 6})
    
    res=MatchIndex1.by_provider("cable").all
    res.size.should ==3
    res[0].id.to_i.should ==a.id
    res[1].id.to_i.should ==c.id
    res[2].id.to_i.should ==f.id

    res=MatchIndex1.by_provider("satellite").all
    res.size.should ==2
    res[0].id.to_i.should ==b.id
    res[1].id.to_i.should ==e.id

    res=MatchIndex1.by_provider("overair").all
    res.size.should ==1
    res[0].id.to_i.should ==d.id

    res=MatchIndex1.by_provider("xxx").all
    res.size.should ==0
  end
end
