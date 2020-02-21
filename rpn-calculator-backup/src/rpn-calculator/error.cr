# Contains all the custom exceptions/errors for the program
module Error
  # Occurs when the user wants to find the factorial of a negative integer
  class FactorialOfNegativeIntegersError < Exception
    def initialize(message = "Error: Cannot find the factorial of a negative integer")
      super message
    end
  end

  # A convenient helper to easily raise an error
  def raise(type : String)
  end
end
