require_relative 'base'

if self.to_s == "main"
  # We are probably at the top level.

  require 'forwardable'
  self.extend Forwardable
  @ajika_app = Class.new(Ajika::Application)
  self.def_delegators :@ajika_app, *Ajika::Application::DSL.instance_methods

  at_exit do
    if $!.nil?
      @ajika_app.run(STDIN.read)
    end
  end
end