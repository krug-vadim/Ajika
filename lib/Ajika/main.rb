require_relative 'base'

module Ajika
  class Application < Base
  end

  at_exit { puts "at_exit" }
end

# include would include the module in Object
# extend only extends the `main` object
extend Ajika::Delegator
