module Ro
  class Template
    require 'erb'
    require 'rouge'
    require 'kramdown'
    require 'kramdown-parser-gfm'

    require_relative 'html.rb'
    require_relative 'template/rouge_formatter.rb'

    def Template.render(*args, &block)
      render_file(*args, &block)
    end

    def Template.render_file(path, options = {})
      path = File.expand_path(path.to_s.strip)
      options = Map.for(options.is_a?(Hash) ? options : { context: options })

      content = IO.binread(path).force_encoding('utf-8')
      engines = File.basename(path).split('.')[1..-1]
      context = options[:context]

      begin
        render_string(content, path: path, engines: engines, context: context)
      rescue Ro::Error => e
        msg = e.message
        Ro.error! "failed to render #{ path } with `#{ msg }`"
      end
    end

    def Template.render_string(content, options = {})
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
            when 'html'
              render_html(content)
            when 'txt', 'text'
              render_text(content)
            when 'erb'
              render_erb(content, context:)
            when 'md', 'markdown'
              render_markdown(content)
            when 'yml', 'yaml'
              render_yaml(content)
            when 'json'
              render_json(content)
            when 'rb'
              render_ruby(content)
            when 'txt', 'text'
              render_text(content)
            else
              Ro.error!("no engine found for engine=#{ engine.inspect } engines=#{ engines.inspect }")
          end
      end

      content
    end

    def Template.render_html(html)
      HTML.new(html)
    end

    def Template.render_json(json)
      data = JSON.parse(json)
      Ro.mapify(data)
    end

    def Template.render_yaml(yaml)
      data = YAML.load(yaml)
      Ro.mapify(data)
    end

    def Template.render_ruby(code)
      string = IO.popen('ruby', 'w+'){|ruby| ruby.puts(code); ruby.close_write; ruby.read}

      if $? == 0
        string
      else
        Ro.error!("ruby:\n\n#{ code }")
      end
    end

    def Template.render_text(text)
      html = Text.render(text)
      HTML.new(html)
    end

    def Template.render_erb(content, options = {})
      content = String(content).force_encoding('utf-8')
      options = Map.for(options.is_a?(Hash) ? options : { context: options })
      context = options[:context]

      erb = ERB.new(content, trim_mode: '%<>')

      html =
        if context.respond_to?(:to_hash)
          hash = context.to_hash
          erb.result_with_hash(hash)
        else
          binding = context ? context.instance_eval{ binding } : ::Kernel.binding
          erb.result(binding)
        end

      HTML.new(html)
    end

    def Template.render_markdown(content, options = {})
      content = String(content).force_encoding('utf-8')
      options = Map.for(options.is_a?(Hash) ? options : { context: options })

      theme = options.fetch(:theme) { Ro.config.md_theme }

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

    def Template.render_src(path, options = {})
      path = File.expand_path(path.to_s.strip)
      options = Map.for(options.is_a?(Hash) ? options : { context: options })

      content = IO.binread(path).force_encoding('utf-8')
      engines = File.basename(path).split('.')[1..-1].reverse
      context = options[:context]

      theme = options.fetch(:theme) { Ro.config.md_theme }
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
