module Ro
  class Template
    require 'erb'
    require 'rouge'
    require 'kramdown'
    require 'kramdown-parser-gfm'

    require_relative 'template/rouge_formatter.rb'

    class HTML < ::String
    end

    def self.render(*args, &block)
      render_file(*args, &block)
    end

    def self.render_file(path, options = {})
      path = File.expand_path(path.to_s.strip)
      options = Map.for(options.is_a?(Hash) ? options : { context: options })

      content = IO.binread(path).force_encoding('utf-8')
      engines = File.basename(path).split('.')[1..-1]
      context = options[:context]

      render_string(content, path: path, engines: engines, context: context)
    end

    def self.render_string(content, options = {})
      content = String(content).force_encoding('utf-8')
      options = Map.for(options.is_a?(Hash) ? options : { context: options })
      engines = Array(options.fetch(:engines) { ['md'] }).flatten.compact
      path = options.fetch(:path) { '(string)' }
      context = options[:context]

      loop do
        break if engines.empty?

        engine = engines.shift.to_s.strip.downcase

        content =
          case engine
            when 'txt', 'text'
              content
            when 'erb'
              render_erb(content, context:)
            when 'md', 'markdown'
              render_markdown(content)
            when 'yml'
              YAML.load(content)
            when 'json'
              JSON.parse(content)
            when 'rb'
              eval(content)
            else
              Ro.error!("no engine found for engine=#{ engine.inspect } engines=#{ engines.inspect }")
          end
      end

      content
    end

    def self.render_erb(content, options = {})
      content = String(content).force_encoding('utf-8')
      options = Map.for(options.is_a?(Hash) ? options : { context: options })
      context = options[:context]

      binding = context ? context.instance_eval{ binding } : ::Kernel.binding

      HTML.new(ERB.new(content, trim_mode: '%<>').result(binding))
    end

    def self.render_markdown(content, options = {})
      content = String(content).force_encoding('utf-8')
      options = Map.for(options.is_a?(Hash) ? options : { context: options })

      theme = options.fetch(:theme) { 'github' }

      opts = {
        input: 'GFM',
        syntax_highlighter_opts: { formatter: RougeFormatter, theme: theme }
      }

      HTML.new(
        <<~_____
          <div class="ro markdown">
            #{ ::Kramdown::Document.new(content, opts).to_html }
          </div>
        _____
      )
    end

    def self.render_src(path, options = {})
      path = File.expand_path(path.to_s.strip)
      options = Map.for(options.is_a?(Hash) ? options : { context: options })

      content = IO.binread(path).force_encoding('utf-8')
      engines = File.basename(path).split('.')[1..-1].reverse
      context = options[:context]

      theme = options.fetch(:theme) { 'github' }
      formatter = RougeFormatter.new(theme: theme)

      language = engines.shift

      lexer = Rouge::Lexer.find(language) || Ro.error!('no lexer found for ')

      content = render_string(content, path: path, engines: engines, context: context) if engines.size.nonzero?

      HTML.new(
        <<~_____
          <div class="ro markdown src">
            #{ formatter.format(lexer.lex(content)) }
          </div>
        _____
      )
    end
  end
end
