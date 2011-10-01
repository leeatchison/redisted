require 'spec_helper'

describe "References" do
  it "can create a reference_one" do
    class Reference1 < Redisted::Base
      field :name, type: :string
    end
    class ReferenceTestB1 < Redisted::Base
      field :name, type: :string
      references_one :reference1
    end
    a=Reference1.create
    b=ReferenceTestB1.create
    b.reference1=a
    a.name="Test1"
    b.name="Test2"
    b.name.should =="Test2"
    b.reference1.name.should =="Test1"
  end
  it "can create a reference_many" do
    class Reference < Redisted::Base
      field :name, type: :string
    end
    class ReferenceTestB2 < Redisted::Base
      field :name, type: :string
      references_many :reference
    end
    a=Reference.create
    b=Reference.create
    c=Reference.create
    d=ReferenceTestB2.create
    d.references<<a
    d.references.add_one b
    d.references<<c
    a.name="TestA"
    b.name="TestB"
    c.name="TestC"
    d.name="TestD"
    d.name.should =="TestD"
    d.references.size.should ==3
    d.references[0].name.should =="TestA"
    d.references[1].name.should =="TestB"
    d.references[2].name.should =="TestC"
  end
  it "can add and change an object in reference_one" do
    class Reference3 < Redisted::Base
      field :name, type: :string
    end
    class ReferenceTestB3 < Redisted::Base
      field :name, type: :string
      references_one :reference3
    end
    a1=Reference3.create
    a2=Reference3.create
    b=ReferenceTestB3.create
    b.reference3=a1
    a1.name="Test1"
    a2.name="Test2"
    b.name="Test3"
    b.name.should =="Test3"
    b.reference3.name.should =="Test1"
    b.reference3=a2
    b.reference3.name.should =="Test2"
  end
  it "can delete an object in a reference_one" do
    class Reference4 < Redisted::Base
      field :name, type: :string
    end
    class ReferenceTestB4 < Redisted::Base
      field :name, type: :string
      references_one :reference4
    end
    a=Reference4.create
    b=ReferenceTestB4.create
    b.reference4=a
    a.name="Test1"
    b.name="Test2"
    b.name.should =="Test2"
    b.reference4.name.should =="Test1"
    a.destroy
    b.reference4.should be_nil
  end
  it "can delete an object in a reference_many" do
    class ReferenceTestA5 < Redisted::Base
      field :name, type: :string
    end
    class ReferenceTestB5 < Redisted::Base
      field :name, type: :string
      references_many :reference_testa5
    end
    a=ReferenceTestA5.create
    b=ReferenceTestA5.create
    c=ReferenceTestA5.create
    d=ReferenceTestB5.create
    d.reference_testa5s<<a
    d.reference_testa5s<<b
    d.reference_testa5s<<c
    a.name="TestA"
    b.name="TestB"
    c.name="TestC"
    d.name="TestD"
    d.name.should =="TestD"
    d.reference_testa5s.size.should ==3
    d.reference_testa5s[0].name.should =="TestA"
    d.reference_testa5s[1].name.should =="TestB"
    d.reference_testa5s[2].name.should =="TestC"
    b.delete
    d.reference_testa5s.size.should ==2
    d.reference_testa5s[0].name.should =="TestA"
    d.reference_testa5s[1].name.should =="TestC"
  end
  it "can call the reference something different" do
    class Reference6 < Redisted::Base
      field :name, type: :string
    end
    class ReferenceTestB6 < Redisted::Base
      field :name, type: :string
      references_one :reference6, as: :test
    end
    a=Reference6.create
    b=ReferenceTestB6.create
    b.test=a
    a.name="Test1"
    b.name="Test2"
    b.name.should =="Test2"
    b.test.name.should =="Test1"
  end
end
