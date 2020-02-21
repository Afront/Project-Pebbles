require "./error"

# Contains the methods for parsing the three types of expressions: prefix, infix, and postfix.
# TODO: Refactor code
# TODO: Support operators with more than one character
# TODO: Move all the code that is not related to parsing out of this module
module Parser
  # Contains the operators of the calculator
  #
  # The key is a string instead of a char type in order to allow operators with more than a character (e.g. ==, >=, !=)
  # Factorial has a higher precedence than exponentiation, which might cause some issues
  # TODO: Figure out a way to allow more than one procs while keeping OPS_HASH a hash
  OPS_HASH = {
    "+" => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a + b }},
    "-" => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a - b }},
    "*" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    "×" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    "/" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    "÷" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    "%" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a % b }},
    "^" => {:precedence => 4, :associativity => :right, :proc => ->(b : Float64, a : Float64) { a ** b }},
    "=" => {:precedence => 1, :associativity => :left, :proc => ->(b : Float64, a : String) { Token.new(a).assign(b) }},
    "!" => {:precedence => 5, :associativity => :right, :proc => ->(n : Float64) { factorial n }},
  }

  # Contains the three types of notation: infix, prefix, and postfix
  private enum Notation
    Infix
    Prefix
    Postfix
  end

  # Converts the *input* that is in prefix notation into postfix notation
  #
  # Might move "to_postfix" methods to Token class
  private def self.prefix_to_postfix(input : String) : String
    stack = [] of Token
    input.split.reverse_each do |token_str|
      token = Token.new(token_str)
      stack << if token.operator?
        Token.new "#{1.upto(token.arity).map { stack.pop.to_s }.join(" ")} #{token.to_s}"
      else
        token
      end
    end
    stack.map { |token| token.to_s }.join(' ')
  end

  # Converts the *input* that is in any notation into postfix notation
  #
  # Might move "to_postfix" methods to Token class
  def self.to_postfix(input : String) : String
    handler = ShuntingYardHandler.new

    case Token.new(input).check_notation
    when Notation::Postfix
      input
    when Notation::Infix
      handler.do_shunting_yard input
    when Notation::Prefix
      prefix_to_postfix input
    else
      ""
    end
  end

  # Contains the number in array form
  #
  # It was originally two classes (Number and Identifier), but I decide merging them into one instead of making a base class
  # Figuring out a way to move it to Token, but I might not do it since Token is already a huge class, which will affect the performance of the program
  private class Number
    property symbols, is_negative

    # Intializes an array of String (instead of char) and a boolean variable
    #
    # I might change @symbols to Char, and @is_negative to (1,-1)
    # I tried changing @is_negative to 1 before, but it did not work (I forgot why)
    def initialize
      @symbols = [] of String
      @is_negative = false
    end

    # Clears the content of symbols and changes is_negative back to false
    # Basically `Number#initialize`
    def clear : Number
      @symbols.clear
      @is_negative = false
      self
    end

    # Outputs the number as a string
    #
    # It has a conditional for 0 to prevent negative zeroes in the program
    def to_s : String
      number = symbols.join.to_s
      (is_negative && number != "0" ? "-" : "") + number
    end

    # Checks if the array is empty, or if the number is nil
    #
    # Was planning on making this method called nil?, but I settled for empty?
    def empty? : Bool
      symbols.empty?
    end

    # Pushes a *token* to the array *symbols*
    def <<(token : String) : Number
      symbols << token
      self
    end
  end

  # Contains the token, which can be manipulated easily with the methods in the class
  # TODO: Refactor class
  class Token
    include Parser

    getter token : String | Float64

    @@var_hash = {
      "e"   => Math::E,
      "PI"  => Math::PI,
      "π"   => Math::PI,
      "TAU" => 2 * Math::PI,
      "τ"   => 2 * Math::PI,
      "PHI" => 0.5 + Math.sqrt(5)/2,
      "φ"   => 0.5 + Math.sqrt(5)/2,
      "ϕ"   => 0.5 + Math.sqrt(5)/2,
    }

    @@factorial_memo = {} of Float64 => Float64

    # Initializes the Token object
    #
    # Considered raising "Token is invalid!" if the token is not valid
    # But I decided not to since I ended up using the class for invalid tokens
    # Which is bad and is probably code smell, so...
    # TODO: Refactor class
    def initialize(@token)
      # raise "Token is invalid!" if !valid?
    end

    # Checks if the token is valid by checking if it's alphanumeric, an operator, or a bracket
    private def valid? : Bool
      alphanumeric? || operator? || bracket?
    end

    # Checks the arity of the *operator*
    #
    # ```
    # Token.new("-").arity # => 2
    # Token.new("!").arity # => 1
    # ```
    # TODO: Make this method private
    def arity(operator : String | Char = token) : Int32
      OPS_HASH[operator.to_s][:proc].as(Proc).arity.to_i
    end

    # Checks if the token is alphanumeric
    #
    # ```
    # Token.new("-").alphanumeric? # => false
    # Token.new("1").alphanumeric? # => true
    # Token.new("a").alphanumeric? # => true
    # # Expressions that should be alphanumeric
    # Token.new("哈羅").alphanumeric? # => false
    # Token.new("꧑").alphanumeric?  # => false
    # Token.new("ᛱ").alphanumeric?  # => false
    # Token.new("๐").alphanumeric?  # => false
    # Token.new("空").alphanumeric?  # => false
    # Token.new("영").alphanumeric?  # => false
    # Token.new("𘈩").alphanumeric?  # => false
    # Token.new("〇").alphanumeric?  # => false
    # ```
    # TODO: Make this method private
    # TODO: Add support for other languages or create a new method that allows this
    def alphanumeric?(tkn : String | Char = token) : Bool
      tkn.to_s.chars.each { |c| return false unless c.alphanumeric? } || true
    end

    # Checks if the token is an operator
    #
    # ```
    # Token.new("-").operator?  # => true
    # Token.new("+").operator?  # => true
    # Token.new("!").operator?  # => true
    # Token.new("-1").operator? # => false
    # Token.new("1").operator?  # => false
    # Token.new("a").operator?  # => false
    # Token.new("哈羅").operator? # => false
    # Token.new("꧑").operator?  # => false
    # Token.new("ᛱ").operator?  # => false
    # Token.new("๐").operator?  # => false
    # Token.new("空").operator?  # => false
    # Token.new("영").operator?  # => false
    # Token.new("𘈩").operator?  # => false
    # Token.new("〇").operator?  # => false
    # ```
    def operator?(tkn : String | Char = token) : Bool
      OPS_HASH.fetch(tkn.to_s, false) != false
    end

    # Checks if the token is a bracket
    #
    # ```
    # Token.new("(").bracket?  # => truee
    # Token.new(")").bracket?  # => true
    # Token.new("-").bracket?  # => false
    # Token.new("+").bracket?  # => false
    # Token.new("!").bracket?  # => false
    # Token.new("-1").bracket? # => false
    # Token.new("1").bracket?  # => false
    # Token.new("a").bracket?  # => false
    # ```
    # TODO: Make this method private
    def bracket?(tkn : String | Char = token) : Bool
      ["(", ")"].includes? token
    end

    # Checks if the token is whitespace
    #
    # ```
    # Token.new("    ").whitespace? # => true
    # Token.new(" ").whitespace?    # => true
    # Token.new("(").whitespace?    # => false
    # Token.new(")").whitespace?    # => false
    # Token.new("-").whitespace?    # => false
    # Token.new("+").whitespace?    # => false
    # Token.new("!").whitespace?    # => false
    # Token.new("-1").whitespace?   # => false
    # Token.new("1").whitespace?    # => false
    # Token.new("a").whitespace?    # => false
    # ```
    # TODO: Make this method private
    def whitespace?(tkn : String | Char = token) : Bool
      tkn.to_s.strip.empty?
    end

    # Checks if the token is a float or a string
    #
    # ```
    # Token.new("a").type?  # => String
    # Token.new(1).type?    # => Float64
    # Token.new(12.0).type? # => Float64
    # ```
    # TODO: Make this method private
    def type : Class
      @token.class
    end

    # Checks if the token is a float
    #
    # ```
    # Token.new("a").float? # => false
    # Token.new(1).float?   # => true
    # Token.new("1").float? # => true
    # ```
    # TODO: Make this method private
    def float? : Bool
      type == Float64 || token.as(String).to_f? != nil
    end

    # Checks if the token is a string
    #
    # ```
    # Token.new("a").string? # => false
    # Token.new(1).string?   # => true
    # Token.new("1").string? # => true
    # ```
    # TODO: Make this method private
    private def string? : Bool
      type == String
    end

    # Checks the notation of the token
    #
    # ```
    # Token.new("+ 1 2").check_notation # => Notation::Prefix
    # Token.new("1 + 2").check_notation # => Notation::Infix
    # Token.new("1 2 +").check_notation # => Notation::Postfix
    # ```
    def check_notation : Notation
      token_str = token.to_s
      exp_array = token_str.split.map { |symbol| symbol[-1].alphanumeric? }

      if ((token_str[0].alphanumeric? ||
         ['-', '+'].includes? token_str[0]) &&
         (operator? token_str[-1]) &&
         token_str[-2].whitespace?)
        Notation::Postfix
      elsif (exp_array[0] && exp_array[-1]) || token_str.includes?(')') || exp_array.size == 1
        Notation::Infix
      elsif exp_array[-2..-1].select(nil).empty?
        Notation::Prefix
      else
        raise ArgumentError.new "This should not occur! Please raise an issue if it does!"
      end
    end

    # Converts the token into a float
    #
    # ```
    # Token.var_hash["a"] = 1
    # Token.new("3").to_f # => 3
    # Token.new(2).to_f   # => 2
    # Token.new("a").to_f # => 1
    # ```
    def to_f : Float64
      token_arr = token.to_s.chars
      is_negative = 1

      while token_arr[0] == '-' || token_arr[0] == '+'
        is_negative *= -1 if token_arr[0] == '-'
        token_arr.shift
      end

      trimmed_token = token_arr.join

      if float?
        token.to_f
      else
        @@var_hash.fetch(trimmed_token, trimmed_token).to_f * is_negative
      end
    end

    # Converts the token to a string
    #
    # ```
    # Token.new("3").to_s # => "3"
    # Token.new(2).to_s   # => "2"
    # Token.new("a").to_s # => "a"
    # Token.new(3.2).to_s # => "3.2"
    # ```
    def to_s : String
      token.to_s
    end

    # Checks if the token is equal to the string/char
    #
    # ```
    # Token.new("3") == "2" # => false
    # Token.new(2) == "2"   # => true
    # ```
    # TODO: Add another conditional that checks if the value is the same
    def ==(other : String | Char) : Bool
      token == other.to_s
    end

    # Checks if the token is equal to another token
    #
    # ```
    # Token.new("3") == "2" # => false
    # Token.new(2) == "2"   # => true
    # ```
    # TODO: Add another conditional that checks if the value is the same
    def ==(other : Token) : Bool
      token == Token.token
    end

    # Gets the var_hash
    def self.var_hash
      @@var_hash
    end

    # Pops the token n amount of times where n is the arity of the operator
    #
    # TODO: Move this method out of the Token class?
    def token_pop(stack : Array(Token)) : Tuple(Array(Token), Tuple(Float64) | Tuple(Float64, Float64) | Tuple(Float64, Float64, Float64))
      popped_tokens = [] of Float64
      arity.times { popped_tokens << stack.pop.to_f }
      # Convert popped_tokens to numbers only -> var to numbers method
      arg_tuple = case arity
                  when 1
                    Tuple(Float64).from(popped_tokens)
                  when 2
                    Tuple(Float64, Float64).from(popped_tokens)
                  when 3
                    Tuple(Float64, Float64, Float64).from(popped_tokens)
                  else
                    raise "Something is wrong with the argument tuple for popping the tokens"
                  end

      {stack, arg_tuple}
    end

    # Applies the operator to the two operands in the stack
    def operate(stack : Array(Token)) : Array(Token)
      raise ArgumentError.new("Error: Not enough arguments!") if stack.size < arity

      if token == "="
        value = stack.pop.to_f
        return stack << Token.new(stack.pop.assign(value))
      end

      stack, popped_tokens = token_pop(stack)

      stack << Token.new(case arity
      when 1
        if token == "!"
          n = popped_tokens[0]
          @@factorial_memo[n.to_f] ||= OPS_HASH[token.to_s][:proc].as(Proc(Float64, Float64)).call(n.to_f).to_f
        else
          OPS_HASH[token.to_s[0]][:proc].as(Proc(Float64, Float64)).call(*popped_tokens.as(Tuple(Float64)))
        end
      when 2
        OPS_HASH[token.to_s][:proc].as(Proc(Float64, Float64, Float64)).call(*popped_tokens.as(Tuple(Float64, Float64)))
        # when 3
        # OPS_HASH[token[0].to_s][:proc].as(Proc(Float64, Float64, Float64, Float64)).call(*popped_tokens.as(Tuple(Float64, Float64, Float64)))
      else
        raise "Something is wrong with the program. Please raise an issue if this occurs"
      end)
      stack
    end

    # Assigns the *value* to a variable
    def assign(value : Float64) : Float64
      @@var_hash[token.to_s] = value
    end
  end

  # Checks if the float is actually an integer or not
  #
  # ```
  # Token.int128?(3.0)                                                          # => true
  # Token.int128?(3.0000000000000000000000000000000000000000000000000000000001) # => true
  # Token.int128?(3.1)                                                          # => false
  # ```
  def self.int128?(n : Float64) : Bool
    n.to_f == n.to_i128
  end

  # Finds the factorial of the number, which can be a negative number or a positive number (as long as it's not a negative integer)
  #
  # ```
  # Token.factorial(1) # => 1.0
  # Token.factorial(2) # => 2.0
  # ```
  private def self.factorial(n : Float64) : Float64
    if int128?(n)
      raise Error::FactorialOfNegativeIntegersError.new if n < 0
      (1..n.to_i).reduce(1.0) { |a, b| a*b*1.0 }
    else
      Math.gamma(n + 1)
    end
  end

  # Contains two states: if the operator is binary or unary
  #
  # TODO: Change DashSignState to State that contains Binary and Unary states
  enum DashSignState
    Negative
    Subtract
  end

  # Contains the methods for the shunting yard algorithm
  private class ShuntingYardHandler
    property output_s, operator_s, number, prev_token, dash_sign_state, curr_token, index, goto_hash, id

    # Intializes the handler
    def initialize
      @hash = {} of String => Float64
      @output_s = [] of String
      @operator_s = [] of String
      @number = Number.new
      @id = Number.new
      @prev_token = " "
      @curr_token = " "
      @dash_sign_state = DashSignState::Negative
      @index = 0
      @goto_hash = {} of String => Proc(Bool)
      load_goto_hash
    end

    # Loads the goto hash
    def load_goto_hash : Hash
      @goto_hash = {"(" => ->{ goto_open }, ")" => ->{ goto_closed }}
      OPS_HASH.each_key do |op|
        @goto_hash.merge!({op => ->{ goto_operator }})
      end
      @goto_hash
    end

    # Goes to the number "state"
    #
    # Originally handle_number because of the stigma against gotos
    # Had to create a separate method for this to meet the standards for Ameba since the shunting yard alg had a high cyclometric complexity.
    def goto_number : Bool
      @operator_s << "*" if @prev_token == ")"
      @prev_token = @curr_token
      @number.symbols << @curr_token
      true
    end

    # Goes to the id "state"
    #
    # Originally handle_id because of the stigma against gotos
    # Had to create a separate method for this to meet the standards for Ameba since the shunting yard alg had a high cyclometric complexity.
    def goto_id : Bool
      @operator_s << "*" if @prev_token == ")" || @prev_token.to_i?
      @prev_token = @curr_token
      @id << @curr_token
      true
    end

    # Goes to the operator "state"
    #
    # Originally handle_operator because of the stigma against gotos
    # Had to create a separate method for this to meet the standards for Ameba since the shunting yard alg had a high cyclometric complexity.
    def goto_operator : Bool
      if dash_sign_state == DashSignState::Negative && ["-", "+"].includes? @curr_token
        @number.is_negative ^= true if @curr_token == "-"
      else
        handle_precedence unless @operator_s.empty?
        @operator_s << @curr_token
        @dash_sign_state = DashSignState::Negative
      end
      true
    end

    # Goes to the open "state"
    #
    # Originally handle_open because of the stigma against gotos
    # Had to create a separate method for this to meet the standards for Ameba since the shunting yard alg had a high cyclometric complexity.
    def goto_open : Bool
      if @prev_token == ")" || @prev_token[-1].alphanumeric?
        handle_precedence unless @operator_s.empty?
        @operator_s << "*"
      end
      @operator_s << "("
      @dash_sign_state = DashSignState::Negative
      true
    end

    # Goes to the closed "state"
    #
    # Originally handle_closed because of the stigma against gotos
    # Had to create a separate method for this to meet the standards for Ameba since the shunting yard alg had a high cyclometric complexity.
    def goto_closed : Bool
      while @operator_s.last != "("
        @output_s << @operator_s.pop.to_s
      end
      raise "Parentheses Error: Missing '(' to match the ')' @ column #{@index + 1}!" if @operator_s.empty?
      @operator_s.pop if @operator_s.last == "("
      @dash_sign_state = DashSignState::Subtract
      true
    end

    # Pushes the operators in the operator stack to the output stack depending on the precedence between the operators
    #
    # Had to create a separate method for this to meet the standards for Ameba since the shunting yard alg had a high cyclometric complexity.
    def handle_precedence : Tuple(Array(String), Array(String))
      unless [@operator_s.last, @curr_token].includes? "("
        top_precedence = OPS_HASH[@operator_s.last][:precedence].as(Int32)
        tkn_precedence = OPS_HASH[@curr_token][:precedence].as(Int32)
        tkn_associativity = OPS_HASH[@curr_token][:associativity].as(Symbol)
        while !@operator_s.empty? && @operator_s.last != "(" &&
              ((top_precedence > tkn_precedence) ||
              (top_precedence == tkn_precedence && tkn_associativity == :left))
          @output_s << @operator_s.pop.to_s
        end
      end
      {@output_s, @operator_s}
    end

    # Converts the given *input* expression that is in infix notation into a postfix expression
    # ```
    # do_shunting_yard("1+2") # => "1 2 +"
    # ```
    def do_shunting_yard(input : String) : String
      input.split("").each do |token|
        @index += 1
        @curr_token = token
        tkn = Token.new(token)
        next if tkn.whitespace?
        next goto_number if (tkn.float? || tkn.to_s == ".") && @id.empty?

        # Originally token.alphanumeric?
        next goto_id unless tkn.operator? || tkn.bracket?

        unless @number.empty?
          @output_s << @number.to_s
          @dash_sign_state = DashSignState::Subtract
          @number.clear
        end

        unless @id.empty?
          @output_s << @id.to_s
          @dash_sign_state = DashSignState::Subtract
          @id.clear
        end

        @goto_hash.fetch(token) { |t| raise "Error: Token #{t} is not supported yet!" }.call
        @prev_token = token
      end

      @output_s << @number.to_s unless @number.empty?
      @output_s << @id.to_s unless @id.empty?

      until @operator_s.empty?
        raise "Parentheses Error: Missing ')' at the end!" if @operator_s.last == "("
        @output_s << @operator_s.pop.to_s
      end

      @output_s.join(" ")
    end
  end
end
