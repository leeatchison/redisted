require 'spec_helper'

describe "basic" do
  it "does nothing successfully" do
    class BigTest < Redisted::Base
      def testit2
        "testit2_in_bigtest"
      end
    end
    a=BigTest.new
    a.testit.should =="testit_in_base"
    a.testit2.should =="testit2_in_bigtest"
  end
end