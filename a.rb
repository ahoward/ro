require 'rouge'

class ::Rouge::Formatters::HTMLInline
  INITIALIZE = instance_method(:initialize)

  def initialize(opts)
    theme = if opts.is_a?(Hash)
              opts[:theme] || opts['theme']
            elsif opts.is_a?(Symbol)
              opts.to_s
            else
              opts
            end

    INITIALIZE.bind(self).call(theme)
  end
end

require 'kramdown'
require 'kramdown-parser-gfm'

theme = 'github' # 'github.dark'

options = {
  input: 'GFM',
  syntax_highlighter: 'rouge',
  syntax_highlighter_opts: { formatter: Rouge::Formatters::HTMLInline, theme: theme }
}

markdown = <<~____
  ```ruby
  @A = 42
  ```
____

def markdown2html(markdown, options = {})
  theme = options[:theme] || options['theme'] || 'github'

  options = {
    input: 'GFM',
    syntax_highlighter: 'rouge',
    syntax_highlighter_opts: { formatter: Rouge::Formatters::HTMLInline, theme: theme }
  }

  html = ::Kramdown::Document.new(markdown, options).to_html
end

# html = Kramdown::Document.new(markdown, options).to_html
html = markdown2html(markdown)

puts html
