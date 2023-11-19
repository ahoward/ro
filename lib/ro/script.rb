module Ro
  def self.script(*args, &block)
    Script.run!(*args, &block)
  end

  class Script
    attr_accessor :cls, :env, :argv, :options, :stdout, :stdin, :stderr, :help

    def run!(env = ENV, argv = ARGV)
      initialize!(env, argv)
      parse_command_line!
      run_mode!
    end

    def initialize!(env, argv)
      @cls = self.class
      @env = env.to_hash.dup
      @argv = argv.map { |arg| arg.dup }
      @options = {}
      @mode = nil
      @stdout = $stdout.dup
      @stdin = $stdin.dup
      @stderr = $stderr.dup
      @help = @cls.help
    end

    def parse_command_line!
      argv = []
      head = []
      tail = []

      %w[--].each do |stop|
        next unless (i = @argv.index(stop))

        head = @argv.slice(0...i)
        tail = @argv.slice((i + 1)...@argv.size)
        @argv = head
        break
      end

      @argv.each do |arg|
        if arg =~ /^\s*--([^\s-]+)=(.+)/
          key = ::Regexp.last_match(1)
          val = ::Regexp.last_match(2)
          @options[key.to_sym] = val
        elsif arg =~ /^\s*(-+)(.+)/
          switch = ::Regexp.last_match(1)
          key = ::Regexp.last_match(2)
          val = switch.size.even?
          @options[key.to_sym] = val
        else
          argv.push(arg)
        end
      end

      argv += tail

      @argv.replace(argv)

      @mode = (@argv.shift if respond_to?("run_#{@argv[0]}!"))
    end

    def run_mode!
      if @mode
        send("run_#{@mode}!")
      else
        run
      end
    end

    def run
      help!
    end

    def run_help!
      @stdout.puts(@help)
    end

    def help!
      @stderr.puts(@help)
      abort
    end

    def log(*messages, io: $stdout)
      ts = Time.now.utc.iso8601
      prefix = File.basename($0)
      msg = messages.join("\n\s\s").strip

      io.write "---\n[#{prefix}@#{ts}]\n\s\s#{msg}\n\n\n"

      begin
        io.flush
      rescue StandardError
        nil
      end
    end

    def err(*messages)
      log(*messages, io: @stderr)
    end

    @@SAY = {
      :clear      => "\e[0m",
      :reset      => "\e[0m",
      :erase_line => "\e[K",
      :erase_char => "\e[P",
      :bold       => "\e[1m",
      :dark       => "\e[2m",
      :underline  => "\e[4m",
      :underscore => "\e[4m",
      :blink      => "\e[5m",
      :reverse    => "\e[7m",
      :concealed  => "\e[8m",
      :black      => "\e[30m",
      :red        => "\e[31m",
      :green      => "\e[32m",
      :yellow     => "\e[33m",
      :blue       => "\e[34m",
      :magenta    => "\e[35m",
      :cyan       => "\e[36m",
      :white      => "\e[37m",
      :on_black   => "\e[40m",
      :on_red     => "\e[41m",
      :on_green   => "\e[42m",
      :on_yellow  => "\e[43m",
      :on_blue    => "\e[44m",
      :on_magenta => "\e[45m",
      :on_cyan    => "\e[46m",
      :on_white   => "\e[47m"
    }

    def say(phrase, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:color] = args.shift.to_s.to_sym unless args.empty?
      keys = options.keys
      keys.each{|key| options[key.to_s.to_sym] = options.delete(key)}

      color = options[:color]
      bold = options.has_key?(:bold)

      parts = [phrase]
      parts.unshift(@@SAY[color]) if color
      parts.unshift(@@SAY[:bold]) if bold
      parts.push(@@SAY[:clear]) if parts.size > 1

      method = options[:method] || :puts

      if STDOUT.tty?
        ::Kernel.send(method, parts.join)
      else
        ::Kernel.send(method, phrase)
      end
    end

    def self.help(*args)
      @help = args.join("\n") unless args.empty?
    end

    def self.run(*args, &block)
      modes =
        if args.empty?
          [nil]
        else
          args
        end

      modes.each do |mode|
        method_name =
          if mode
            "run_#{mode}!"
          else
            'run'
          end

        define_method(method_name, &block)
      end
    end

    def self.run!(&block)
      STDOUT.sync = true
      STDERR.sync = true

      %w[PIPE INT].each { |signal| Signal.trap(signal, 'EXIT') }

      Class.new(Script, &block).new.run!(ENV, ARGV)
    end
  end
end
