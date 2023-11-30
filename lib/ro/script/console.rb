module Ro
  class Script::Console
    class << self
      def run!(...)
        new(...).run!
      end
    end

    def initialize(script:)
      @script = script
    end

    def run!
      $A_GIANT_FUCKING_HACK_FOR_IBB = ARGV.clear

      require 'irb'

      $GIANT_FUCKING_HACK = IRB.method(:load_modules)

      Kernel.module_eval do
        def ro
          Ro.root
        end
      end

      def IRB.load_modules
        $GIANT_FUCKING_HACK.call

        prompt = "ro[./#{Ro.root.relative_to(Dir.pwd)}]"

        IRB.conf[:PROMPT][:RO] = {
          PROMPT_I: "#{prompt}:%03n:%i> ",
          PROMPT_N: "#{prompt}:%03n:%i> ",
          PROMPT_S: "#{prompt}:%03n:%i%l ",
          PROMPT_C: "#{prompt}:%03n:%i* ",
          RETURN: "=> %s\n"

        }

        IRB.conf[:PROMPT_MODE] = :RO
        IRB.conf[:AUTO_INDENT] = true
      end

      ::IRB.start
    end
  end
end
