require "./spec_helper"

include RPNCalculator

describe RPNCalculator do
  # TODO: Write tests
  describe "#calculate" do
    calc = RPNCalculator::Calculator.new

    describe "it accepts postfix expressions" do
      it "adds correctly" do
        calc.calculate("1 2 +").should eq(3.0)
        calc.calculate("21 2.1 +").should eq(23.1)
      end

      it "subtracts correctly" do
        calc.calculate("1 2 -").should eq(-1.0)
        calc.calculate("2 1 -").should eq(1.0)
        calc.calculate("20.1 1 -").should eq(19.1)
      end

      it "multiplies correctly" do
        calc.calculate("1 2 *").should eq(2.0)
        calc.calculate("2 -1 *").should eq(-2.0)
        calc.calculate("0.5 -2 *").should eq(-1.0)
        calc.calculate("-20 ----2 ×").should eq(-40.0)
        calc.calculate("0.25 +++4 ×").should eq(1.0)
      end

      it "divides correctly" do
        calc.calculate("1 -2 /").should eq(-0.5)
        calc.calculate("2 1 /").should eq(2.0)
        calc.calculate("100000000 5 ÷").should eq(20000000.0)
        expect_raises(DivisionByZeroError, "Error: Attempted dividing by zero") do
          calc.calculate("10000500 0 / ")
        end
      end

      it "finds the remainder correctly" do
        calc.calculate("1 2 %").should eq(1.0)
        calc.calculate("1 -1 %").should eq(0.0)
        calc.calculate("100 8 %").should eq(4.0)
      end

      it "finds the power of a number correctly" do
        calc.calculate("10 2 ^").should eq(100.0)
        calc.calculate("1 -1 ^").should eq(1.0)
        calc.calculate("4 1 2 / ^").should eq(2.0)
      end

      it "finds the factorial correctly" do
        calc.calculate("0 !").should eq(1.0)
        calc.calculate("1 !").should eq(1.0)
        calc.calculate("2 !").should eq(2.0)
        # calc.calculate("100 !").should eq(93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000.0)
        calc.calculate("50 !").should eq(30414093201713378043612608166064768844377641568960512000000000000.0)
        calc.calculate("-0.5 !").should eq(Math.gamma(0.5))
        expect_raises(Error::FactorialOfNegativeIntegersError, "Cannot find the factorial of a negative integer") do
          calc.calculate("-1 !")
        end
      end

      it "can handle assignments" do
        calc.calculate("a 2 =").should eq(2.0)
        calc.calculate("b 3 =").should eq(3.0)
        calc.calculate("a b +").should eq(5.0)
        calc.calculate("3 b +").should eq(6.0)
        calc.calculate("c 3 2 + 5 * 2 * =").should eq(50.0)
        calc.calculate("c").should eq(50.0)
      end

      it "can correctly evaluate 'polynomials'" do
        calc.calculate("3 1 2 + 2 - /").should eq(3.0)
        calc.calculate("b 1 a 4 1 2 / ^ = + a + =").should eq(5.0)
        calc.calculate(" 10 1 - ! 2 / 3 4 ^ * 3.14 +").should eq(14696643.14)
        calc.calculate(" 10 1 - ! 2 3 4 ^ * / PI +").should eq(2240 + Math::PI)
      end
    end

    describe "it accepts infix expressions" do
      it "adds correctly" do
        calc.calculate("1 + 2").should eq(3.0)
        calc.calculate("21 + 2.1").should eq(23.1)
        calc.calculate("100 + -5").should eq(95.0)
        calc.calculate("-100 + +5").should eq(-95.0)
        calc.calculate("--0110 + ++5").should eq(115.0)
        calc.calculate("(25) + (3)").should eq(28.0)
      end

      it "subtracts correctly" do
        calc.calculate("1 - --2 ").should eq(-1.0)
        calc.calculate("+++++2 - 1 ").should eq(1.0)
        calc.calculate("--20.1 - 1 ").should eq(19.1)
        calc.calculate("(25) - -(--3.1)").should eq(28.1)
      end

      it "multiplies correctly" do
        calc.calculate("1 * 2").should eq(2.0)
        calc.calculate("2 * (-1) ").should eq(-2.0)
        calc.calculate("0.5(-2)").should eq(-1.0)
        calc.calculate("-20 × ----2 ").should eq(-40.0)
        calc.calculate("0.25 × +++4").should eq(1.0)
        calc.calculate("(-3)5").should eq(-15.0)
        calc.calculate("2(-3)5").should eq(-30.0)
      end

      it "divides correctly" do
        calc.calculate("1 / -2 ").should eq(-0.5)
        calc.calculate("2 / +1 ").should eq(2.0)
        calc.calculate("100000000 ÷ --5 ").should eq(20000000.0)
        calc.calculate("500/-(-25) ").should eq(20.0)
        expect_raises(DivisionByZeroError, "Error: Attempted dividing by zero") do
          calc.calculate("10000500/--(---0) ")
        end
      end

      it "finds the remainder correctly" do
        calc.calculate("1 % 2 ").should eq(1.0)
        calc.calculate("1 % -1 ").should eq(0.0)
        calc.calculate("100 % 8 ").should eq(4.0)
      end

      it "finds the power of a number correctly" do
        calc.calculate("10 ^ 2 ").should eq(100.0)
        calc.calculate("1 ^ -1 ").should eq(1.0)
        calc.calculate("4 ^ (1/2)  ").should eq(2.0)
        calc.calculate("6 ^ 1/2  ").should eq(3.0)
      end

      it "finds the factorial correctly" do
        calc.calculate("0!").should eq(1.0)
        calc.calculate("-0.5!").should eq(Math.gamma(0.5))
        calc.calculate("1!").should eq(1.0)
        calc.calculate("2!").should eq(2.0)
        # calc.calculate("100!").should eq(93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000.0)
        calc.calculate("50!").should eq(30414093201713378043612608166064768844377641568960512000000000000.0)
        expect_raises(Exception) do
          calc.calculate("-1!")
        end
      end

      it "can handle assignments" do
        calc.calculate("a = 2 ").should eq(2.0)
        calc.calculate("b = 3 ").should eq(3.0)
        calc.calculate("a + b ").should eq(5.0)
        calc.calculate("3 + b ").should eq(6.0)
        calc.calculate("c = (3 + 2)5(2)").should eq(50.0)
        calc.calculate("c").should eq(50.0)
      end

      it "can correctly evaluate 'polynomials'" do
        calc.calculate("3 / (1 + 2 - 2)").should eq(3.0)
        calc.calculate("b = 1 + (a = 4^(1/2)) + a").should eq(5.0)
        calc.calculate("(10-1)!/2×3^4 + 3.14").should eq(14696643.14)
      end
    end

    describe "it accepts prefix expressions" do
      it "adds correctly" do
        calc.calculate("+ 1 2").should eq(3.0)
        calc.calculate("+ 21 2.1").should eq(23.1)
      end

      it "subtracts correctly" do
        calc.calculate("- 1 2").should eq(-1.0)
        calc.calculate("- 2 1").should eq(1.0)
        calc.calculate("- 20.1 1").should eq(19.1)
      end

      it "multiplies correctly" do
        calc.calculate("* 1 2").should eq(2.0)
        calc.calculate("* 2 -1 ").should eq(-2.0)
        calc.calculate("* 0.5 -2 ").should eq(-1.0)
        calc.calculate("× -20 ----2 ").should eq(-40.0)
        calc.calculate("× 0.25 +++4").should eq(1.0)
      end

      it "divides correctly" do
        calc.calculate("/ 1 -2").should eq(-0.5)
        calc.calculate("/ 2 1 ").should eq(2.0)
        calc.calculate("÷ 100000000 5").should eq(20000000.0)

        expect_raises(DivisionByZeroError, "Error: Attempted dividing by zero") do
          calc.calculate("/ 1000 0 ")
        end
      end

      it "finds the remainder correctly" do
        calc.calculate("% 1 2").should eq(1.0)
        calc.calculate("% 1 -1").should eq(0.0)
        calc.calculate("% 100 8").should eq(4.0)
      end

      it "finds the power of a number correctly" do
        calc.calculate("^ 10 2").should eq(100.0)
        calc.calculate("^ 1 -1").should eq(1.0)
        calc.calculate("^  4 / 1 2").should eq(2.0)
        calc.calculate("^ / 4 1 2").should eq(16.0)
      end

      it "finds the factorial correctly" do
        calc.calculate("! 0 ").should eq(1.0)
        calc.calculate("! 1 ").should eq(1.0)
        calc.calculate("! 2 ").should eq(2.0)
        # calc.calculate("! 100 ").should eq(93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000.0)
        calc.calculate("! 50 ").should eq(30414093201713378043612608166064768844377641568960512000000000000.0)
        expect_raises(Exception) do
          calc.calculate("! -1")
        end
      end

      it "can handle assignments" do
        calc.calculate("= a 2 ").should eq(2.0)
        calc.calculate("= b 3").should eq(3.0)
        calc.calculate("+ a b").should eq(5.0)
        calc.calculate("+ 3 b").should eq(6.0)
        calc.calculate("= c * * + 3 2 5 2 ").should eq(50.0)
        calc.calculate("c").should eq(50.0)
      end

      it "can correctly evaluate 'polynomials'" do
        calc.calculate("/ 3 - + 1 2 2").should eq(3.0)
        calc.calculate("/ - 3 + 1 2 2").should eq(0.0)
        calc.calculate("b 1 a 4 1 2 / ^ = + a + =").should eq(5.0)
        calc.calculate("= b + 1 + a = ^ / 4 1 2 a").should eq(5.0)
        calc.calculate("+ * / ! - 10 1 2 ^ 3 4 3.14").should eq(14696643.14)
        calc.calculate("+ / ! - 10 1 * 2 ^ 3 4 PI ").should eq(2240 + Math::PI)
      end
    end
  end

  describe "#repl" do
  end
end
