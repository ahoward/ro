module Ro
  class Template
    require 'rouge'

    class RougeFormatter < ::Rouge::Formatters::HTMLInline
      def initialize(opts)
        theme = if opts.is_a?(Hash)
                  opts[:theme] || opts['theme']
                elsif opts.is_a?(Symbol)
                  opts.to_s
                else
                  opts
                end

        super(theme)
      end

      def stream(tokens)
        lineno = 1
        yield "<code class='code' style='white-space:pre;'>"
        token_lines(tokens).each do |line_tokens|
          yield "<div class='code-line code-line-#{lineno}'>"
          line_tokens.each do |token, value|
            yield span(token, value)
          end
          yield "\n"
          yield '</div>'
          lineno += 1
        end
        yield '</code>'
      end

      def safe_span(tok, safe_val)
        # return safe_val if tok == ::Rouge::Token::Tokens::Text
        return safe_val.gsub(/\s/, '&nbsp;').gsub(/\n/, '<br />') if tok == ::Rouge::Token::Tokens::Text

        rules = @theme.style_for(tok).rendered_rules
        "<span style=\"#{rules.to_a.join(';')}\">#{safe_val}</span>"
      end
    end
  end
end
