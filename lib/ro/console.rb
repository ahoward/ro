module Ro
  class Console
    def self.start!
      setup!
      ::IRB.start
    end

    def self.setup!
      ARGV.clear
      require 'irb'

      Kernel.module_eval do
        def reload!
          Object.send(:remove_const, :Ro)
          "#{$libdir}/ro.rb".tap { |lib| load(lib) }
        end
      end

      $GIANT_FUCKING_HACK = IRB.method(:load_modules)

      def IRB.load_modules
        $GIANT_FUCKING_HACK.call

        prompt = "ro[./#{Ro.relative_path(Ro.root, from: Dir.pwd)}]"

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
    end
  end
end
