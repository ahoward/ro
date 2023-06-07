module Ro
  class Template
    require 'rouge'
    require 'kramdown'
    require 'kramdown-parser-gfm'

    require_relative 'template/rouge_formatter'

    def self.render(*args, &block)
      render_file(*args, &block)
    end

    def self.render_file(path, options = {})
      path = File.expand_path(path.to_s.strip)
      options = Map.for(options.is_a?(Hash) ? options : { context: options })

      content = IO.binread(path).force_encoding('utf-8')
      engines = File.basename(path).split('.')[1..-1].reverse
      context = options[:context]

      render_string(content, path: path, engines: engines, context: context)
    end

    def self.render_string(content, options = {})
      content = String(content).force_encoding('utf-8')

      options = Map.for(options.is_a?(Hash) ? options : { context: options })

      engines = Array(options.fetch(:engines) { ['erb'] }).flatten.compact

      path = options.fetch(:path) { '(string)' }

      context = options[:context]

      loop do
        break if engines.empty?

        engine = engines.shift.to_s.strip.downcase

        content =
          case engine
          when 'yml'
            YAML.load(content)

          when 'json'
            JSON.parse(content)

          when 'md', 'markdown'
            render_markdown(content)

          else
            tilt = Tilt[engine]

            Ro.error!("no rendering engine for path=#{path}, engine=#{engine}!") unless tilt

            yield_handler = proc do |*_args|
              :noop
            end

            tilt.new { content }.render(context, &yield_handler)
          end
      end

      content
    end

    def self.render_markdown(content, options = {})
      content = String(content).force_encoding('utf-8')
      options = Map.for(options.is_a?(Hash) ? options : { context: options })

      theme = options.fetch(:theme) { 'github' }

      opts = {
        input: 'GFM',
        syntax_highlighter: 'rouge',
        syntax_highlighter_opts: { formatter: RougeFormatter, theme: theme }
      }

      ::Kramdown::Document.new(content, opts).to_html
    end

    def self.render_src(path, options = {})
      path = File.expand_path(path.to_s.strip)
      options = Map.for(options.is_a?(Hash) ? options : { context: options })

      content = IO.binread(path).force_encoding('utf-8')
      engines = File.basename(path).split('.')[1..-1].reverse
      context = options[:context]

      theme = options.fetch(:theme) { 'github' }

      language = engines.shift
      formatter = RougeFormatter.new(theme)

      lexer = Rouge::Lexer.find(language) || Ro.error!('no lexer found for ')

      content = render_string(content, path: path, engines: engines, context: context) if engines.size.nonzero?

      formatter.format(lexer.lex(content))
    end
  end
end

if $0 == __FILE__
  require_relative '../ro'

  if ARGV[0]
    path = ARGV[0]
    html = Ro::Template.render(path)
    puts html
  else
    context = Class.new do
      def initialize
        @date = Date.today
      end

      attr_reader :date
    end.new

    string = <<~____
      <%= date %>
      ---

      - a
      - b
      - c

      ```ruby
      class C
        @ANSWER = 42
      end

      a = 42
      b = 42.0
      ```
    ____

    html = Ro::Template.render_string(string, engines: %w[erb md], context: context)
    puts html

    puts '<hr /><hr /><hr />'

    html = Ro::Template.render_src(__FILE__)
    puts html
  end
end
