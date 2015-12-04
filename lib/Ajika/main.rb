require_relative 'base'

if self.to_s == "main"
  # We are probably at the top level.

  puts "We are probably at the top level."

  require 'forwardable'
  self.extend Forwardable
  @ajika_app = Class.new(Ajika::Application)
  self.def_delegators :@ajika_app, *Ajika::Application::DSL.instance_methods

  at_exit do
    # Don't run @angelo_app on uncaught exceptions including exit
    # being called which raises SystemExit.  The rationale being that
    # exit means exit, not "run the server".
    if $!.nil?
      @ajika_app.run(STDIN.read)
    end
  end
end