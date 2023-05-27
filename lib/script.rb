#! /usr/bin/env ruby
 
=begin

  # example script
  #
    ~> cat ./script/a.rb

    #! /usr/bin/env ruby
    #  encoding: utf-8

    script do
      help <<~____
        NAME
          # FIXME

        TL;DR;
          # FIXME
      ____

      run do
        p [@mode, @argv, @options]
      end

      run(:foo) do
        p [@mode, @argv, @options]
      end

      run(:bar) do
        p [@mode, @argv, @options]
      end
    end


    BEGIN {
      require_relative '../lib/script.rb'
    }

  # example usage
  #
    ~> ./script/a.rb arg1 arg2 k:v K=v a: A:
    [nil, ["arg1", "arg2"], {"k"=>"v", "K"=>"v", "a"=>true, "A"=>true}]

    ~> ./script/a.rb foo arg1 arg2 k:v K=v a: A:
    ["foo", ["arg1", "arg2"], {"k"=>"v", "K"=>"v", "a"=>true, "A"=>true}]

    ~> ./script/a.rb bar arg1 arg2 k:v K=v a: A:
    ["bar", ["arg1", "arg2"], {"k"=>"v", "K"=>"v", "a"=>true, "A"=>true}]

    ~> ./script/a.rb =m ==n ===o ====p
    [nil, [], {"m"=>true, "n"=>false, "o"=>true, "p"=>false}]

=end

#
  require 'json'
  require 'yaml'
  require 'base64'
  require 'securerandom'
  require 'fileutils'
  require 'pathname'
  require 'set'
  require 'openssl'
  require 'uri'
  require 'cgi'
  require 'shellwords'
  require 'tmpdir'
  require 'tempfile'

#
  def script(*args, &block)
    Script.run!(*args, &block)
  end

#
  class Script
    attr_accessor :source
    attr_accessor :root
    attr_accessor :env
    attr_accessor :argv
    attr_accessor :stdout
    attr_accessor :stdin
    attr_accessor :stderr
    attr_accessor :help

    def run!(env = ENV, argv = ARGV)
      setup!(env, argv)
      parse_command_line!
      set_mode!
      run_mode!
    end

    def setup!(env, argv)
      @klass = self.class
      @env = env.to_hash.dup
      @argv = argv.map{|arg| arg.dup}
      @stdout = $stdout.dup
      @stdin = $stdin.dup
      @stderr = $stderr.dup
      @help = @klass.help || Util.unindent(DEFAULT_HELP)
    end

    DEFAULT_HELP = <<-__
      NAME
        #TODO

      SYNOPSIS
        #TODO
         
      DESCRIPTION
        #TODO
         
      EXAMPLES
        #TODO
    __

    def parse_command_line!
      @options = Hash.new

      argv = []
      head = []
      tail = []

      %w[ @@ -- ].each do |stop|
        if((i = @argv.index(stop)))
          head = @argv.slice(0 ... i)
          tail = @argv.slice((i + 1) ... @argv.size) 
          @argv = head
          break
        end
      end

      @argv.each do |arg|
        case
          when arg =~ %r`^\s*@([^@\s]+)=(.+)`
            key = $1
            val = $2
            @options[key] = val
          when arg =~ %r`^\s*(@+)(.+)`
            switch = $1
            key = $2
            val = switch.size.odd?
            @options[key] = val
          else
            argv.push(arg)
        end
      end

      u.symbolize_keys!(@options)

      #@options.keys.each do |key|
        #@options[key.to_s.to_sym] = @options[key.to_s]
      #end

      argv += tail

      @argv.replace(argv)
    end

    def set_mode!
      case
        when respond_to?("run_#{ @argv[0] }!")
          @mode = @argv.shift
        else
          @mode = nil
      end
    end

    def run_mode!
      if @mode
        send("run_#{ @mode }!")
      else
        run
      end
    end

    def run
      if @argv.empty?
        run_help!
      else
        abort("#{ $0 } help")
      end
    end

    def run_help!
      STDOUT.puts(@help)
    end

    def help!
      run_help!
      abort
    end

  #
    module Util
      def unindent(arg)
        string = arg.to_s.dup
        margin = nil
        string.each_line do |line|
          next if line =~ %r/^\s*$/
          margin = line[%r/^\s*/] and break
        end
        string.gsub!(%r/^#{ margin }/, "") if margin
        margin ? string : nil
      end

      def esc(*args)
        args.flatten.compact.map{|arg| Shellwords.escape(arg)}.join(' ')
      end

      def uuid
        SecureRandom.uuid
      end

      def tmpname(*args)
        opts = extract_options!(*args)

        base = opts.fetch(:base){ uuid }.to_s.strip
        ext = opts.fetch(:ext){ 'tmp' }.to_s.strip.sub(/^[.]+/, '')
        basename = opts.fetch(:basename){ "#{ base }.#{ ext }" }

        File.join(Dir.tmpdir, basename)
      end

      def tmpfile(*args, &block)
        opts = extract_options!(args)

        path = tmpname(opts)


        tmp = open(path, 'w+')
        tmp.binmode
        tmp.sync = true

        unless args.empty?
          src = args.join
          tmp.write(src)
          tmp.flush
          tmp.rewind
        end

        if block
          begin
            block.call(tmp)
          ensure
            FileUtils.rm_rf(path)
          end
        else
          at_exit{ Kernel.system("rm -rf #{ esc(path) }") }
          return tmp
        end
      end

      def extract_options!(args)
        unless args.is_a?(Array)
          args = [args]
        end

        opts = args.last.is_a?(Hash) ? args.pop : {}

        symbolize_keys!(opts)

        return opts
      end

      def extract_options(args)
        opts = extract_options!(args)

        args.push(opts)

        opts
      end

      def symbolize_keys!(hash)
        hash.keys.each do |key|
          val = hash.delete(key)

          if val.is_a?(Hash)
            symbolize_keys!(val)
          end

          hash[key.to_s.gsub('-', '_').to_sym] = val
        end

        return hash
      end

      def symbolize_keys(hash)
        symbolize_keys(copy(hash))
      end

      def copy(object)
        Marshal.load(Marshal.dump(object))
      end

      def debug?
        ENV['DEBUG']
      end

      def debug!(arg)
        if debug?
          if arg.is_a?(String)
            warn "[script.rb] #{ arg }"
          else
            warn "[script.rb] #{ arg.inspect }"
          end
        end
      end

      def sys!(*args, &block)
        opts = extract_options!(args)

        cmd = args

        debug!(:cmd => cmd)

        open3 = (
          block ||
          opts[:stdin] ||
          opts[:quiet] ||
          opts[:capture]
        )

        if(open3)
          stdin = opts[:stdin]
          stdout = ''
          stderr = ''
          status = nil

          Open3.popen3(*cmd) do |i, o, e, t|
            ot = async_reader_thread_for(o, stdout) 
            et = async_reader_thread_for(e, stderr) 

            i.write(stdin) if stdin
            i.close

            ot.join
            et.join

            status = t.value
          end

          if status.exitstatus == 0
            result = nil

            if opts[:capture]
              result = stdout.to_s.strip
            else
              if block
                result = block.call(status, stdout, stderr)
              else
                result = [status, stdout, stderr]
              end
            end

            return(result)
          else
            abort("#{ [cmd].join(' ') } #=> #{ status.exitstatus }")
          end
        else
          system(*cmd) || abort("#{ [cmd].join(' ') } #=> #{ $?.exitstatus }")
          return true
        end
      end

      def sys(*args, &block)
        begin
          sys!(*args, &block)
        rescue Object
          false
        end
      end

      def async_reader_thread_for(io, accum)
        Thread.new(io, accum) do |i, a|
          Thread.current.abort_on_exception = true

          while true
            buf = i.read(8192)

            if buf
              a << buf
            else
              break
            end
          end
        end
      end

      def realpath(path)
        Pathname.new(path.to_s).expand_path.realpath.to_s
      end

      def filelist(*args, &block)
        accum = (block || proc{ Set.new }).call
        raise ArgumentError.new('accum.class != Set') unless accum.is_a?(Set)

        _ = args.last.is_a?(Hash) ? args.pop : {}

        entries = args.flatten.compact.map{|arg| realpath("#{ arg }")}.uniq.sort

        entries.each do |entry|
          case
            when test(?f, entry)
              file = realpath(entry)
              accum << file

            when test(?d, entry)
              glob = File.join(entry, '**/**')

              Dir.glob(glob) do |_entry|
                case
                  when test(?f, _entry)
                    filelist(_entry){ accum }
                  when test(?d, entry)
                    filelist(_entry){ accum }
                end
              end
          end
        end

        accum.to_a
      end

      def expandenv!(file)
        result = Result.new 
        return result unless(test(?s, file) && test(?f, file))

        buf = IO.binread(file)
        var = /[$]\s*{\s*([0-9a-zA-Z_-]+)(?::-([^}]+))?\s*}/iomx

        buf.gsub!(var) do
          key = $1
          val = (ENV[key] || $2)

          if val
            val = val.to_s.strip
            result[key] = val
            result.success = true
            val
          else
            result[key] = nil
            ""
          end
        end

        if result.success?
          IO.binwrite(file, buf)
        end

        result
      end

      def slug_for(*args, &block)
        Slug.for(*args, &block)
      end

      extend Util
    end

    def Script.utils(&block)
      block ? Util.module_eval(&block) : Util
    end

    def utils
      Util
    end

    def u
      Util
    end

  #
    class Slug < ::String
      Join = '-'

      def Slug.for(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}

        join = (options[:join] || options['join'] || Join).to_s

        string = args.flatten.compact.join(' ')

        tokens = string.scan(%r`[^\s#{ join }]+`)

        tokens.map! do |token|
          token.gsub(%r`[^\p{L}/.]`, '').downcase
        end

        tokens.map! do |token|
          token.gsub(%r`[/.]`, join * 2)
        end

        tokens.join(join)
      end
    end

  #
    class Result < Hash
      def success
        if defined?(@status)
          @status == :success
        else
          (not empty? and values.all?)
        end
      end

      def success=(bool)
        bool = !!bool

        if bool
          @status == :success
        else
          @status == :failure
        end
      end

      alias_method :success?, :success

    #
      def failure
        if defined?(@status)
          @status == :failure
        else
          (empty? or values.none?)
        end
      end

      def failure=(bool)
        bool = !!bool

        if bool
          @status == :failure
        else
          @status == :success
        end
      end

      alias_method :failure?, :failure

    #
      def status
        if defined?(@status)
          return @status
        else
          nil
        end
      end

      def status=(bool)
        @status = !!bool
      end

      alias_method :status?, :status
    end


  #
    def noop
      ENV['NOOP']
    end

    alias_method :noop?, :noop

  #
    def Script.help(*args)
      @help ||= nil

      unless args.empty?
        @help = utils.unindent(args.join)
      end

      @help
    end

    def Script.run(*args, &block)
      modes =
        if args.empty?
          [nil]
        else
          args
        end

      modes.each do |mode|
        method_name =
          if mode
            "run_#{ mode }!"
          else
            "run"
          end

        define_method(method_name, &block)
      end
    end

  #
    def Script.klass_for(&block)
      Class.new(Script) do |klass|
        def klass.name; 'Script::Klass'; end
        klass.class_eval(&block)
      end
    end

    def Script.run!(*args, &block)
      STDOUT.sync = true
      STDERR.sync = true

      %w[ PIPE INT ].each{|signal| Signal.trap(signal, "EXIT")}

      script = (
        source = 
          if binding.respond_to?(:source_location)
            File.expand_path(binding.source_location.first)
          else
            File.expand_path(eval('__FILE__', block.binding))
          end

        root = File.dirname(source)

        klass = Script.klass_for(&block)

        instance = klass.new

        instance.source = source
        instance.root = root

        instance
      )

      script.run!(*args)
    end
  end

BEGIN { 
  Object.send(:remove_const, :Script) if Object.const_defined?(:Script)

  def Script(*args, &block)
    script(*args, &block)
  end
}


if $0 == __FILE__
  template = <<~__TEMPLATE__
    #! /usr/bin/env ruby
    #  encoding: utf-8

    require_relative '../lib/script.rb'

    script do
      help <<~____
        NAME
          # FIXME

        TL;DR;
          # FIXME
      ____

      run do
        p [@mode, @argv, @options]
      end

      run(:foo) do
        p [@mode, @argv, @options]
      end

      run(:bar) do
        p [@mode, @argv, @options]
      end
    end
  __TEMPLATE__

  puts template
end
