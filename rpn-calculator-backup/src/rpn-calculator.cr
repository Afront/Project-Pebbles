require "colorize"
require "readline"
require "./rpn-calculator/*"

# RPNCalculator is a calculator that uses the postfix notation.
# It also accepts expressions that uses the infix notation via the shunting yard algorithm
# It accepts prefix expressions as well!
# Since this is pretty much identical to rpn-calculator-automata, I might merge them back together
# TODO: Add documentation
module RPNCalculator
  VERSION = "0.3.0"

  extend Error

  # This class includes all methods required for a calculator: getting the input, calculating the result, formatting the result, and printing the result!
  # I was planning on putting the operators here as well, but they ended up on the Parser module either as a part of the OPS_HASH or as a part of the Token class
  class Calculator
    # Calculates the result based on the *input* expression given
    #
    # ```
    # calc = Calculator.new
    # calc.calculate("1 2 +")  # => 3
    # calc.calculate("20÷2/2") # => 5
    # calc.calculate("1+2*3")  # => 7
    # calc.calculate("+ 2 7")  # => 9
    # ```
    def calculate(input : String) : Float64
      input = Parser.to_postfix input.strip

      stack = [] of Parser::Token
      input.split.each do |string|
        token = Parser::Token.new(string)
        raise DivisionByZeroError.new("Error: Attempted dividing by zero") if token == "/" && ["0", "0.0"].includes? stack.last.to_s
        if token.operator?
          stack = token.operate(stack)
        else
          stack << token
        end
      end
      raise ArgumentError.new("Error: Missing operator!") if stack.size > 1
      stack.pop.to_f
    end

    # Formats the result of the *input* expression after calculating the result
    #
    # ```
    # format("1 2 +")   # => 3
    # format("3 2.1 +") # => 5.1
    # ```
    def format(input : String) : String
      result = calculate input
      (Parser.int128?(result.to_f) ? result.to_i128 : result.to_f).to_s
    end

    # Prints the result of the input given by the user
    #
    # ```
    # repl # => >
    # ```
    def repl
      until ["abort", "exit", "quit", "q"].includes?(input = (Readline.readline(prompt: "> ", add_history: true) || "").to_s)
        begin
          next if input.strip.empty?
          puts format input
        rescue error_msg : Exception
          puts error_msg.colorize(:red) # , error_msg.backtrace
        end
      end
    end
  end
end

calc = RPNCalculator::Calculator.new
calc.repl
