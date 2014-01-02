require 'tilt'

module Tilt
  class SyntaxHighlightingRedcarpetTemplate < Template
    self.default_mime_type = 'text/html'

    def self.engine_initialized?
      defined?(::Redcarpet) && defined?(::Pygments) && defined?(::ERB)
    end

    def initialize_engine
      require_template_library('redcarpet')
      require_template_library('pygments')
      require_template_library('erb')
    end

    def prepare
      @engine =
        Redcarpet::Markdown.new(
          syntax_highlighting_renderer,
      
          :no_intra_emphasis            => true,
          :tables                       => true,
          :fenced_code_blocks           => true,
          :autolink                     => true,
          :disable_indented_code_blocks => true,
          :strikethrough                => true,
          :lax_spacing                  => true,
          :space_after_headers          => false,
          :superscript                  => true,
          :underline                    => true,
          :highlight                    => true,
          :quote                        => true,

          :with_toc_data                => true,
          :hard_wrap                    => true,
        )

      @output = nil
    end

    def syntax_highlighting_renderer
      Class.new(Redcarpet::Render::HTML) do
        def block_code(code, language)
          language = 'ruby' if language.to_s.strip.empty?
          ::Pygments.highlight(code, :lexer => language, :options => {:encoding => 'utf-8'})
        end
      end
    end

    def evaluate(scope, locals, &block)
      binding =
        if scope.is_a?(::Binding)
          scope
        else
          scope.instance_eval{ ::Kernel.binding }
        end

      @engine.render(erb(data, binding))
    end
    
    def erb(string, binding)
      string
    end

    def allows_script?
      true
    end
  end

  class ERBSyntaxHighlightingRedcarpetTemplate < SyntaxHighlightingRedcarpetTemplate
    def erb(string, binding)
      ::ERB.new(string).result(binding)
    end
  end
end

Tilt.prefer(Tilt::SyntaxHighlightingRedcarpetTemplate, 'md')
Tilt.prefer(Tilt::SyntaxHighlightingRedcarpetTemplate, 'markdown')
Tilt.prefer(Tilt::ERBSyntaxHighlightingRedcarpetTemplate, 'md.erb')
Tilt.prefer(Tilt::ERBSyntaxHighlightingRedcarpetTemplate, 'markdown.erb')


if $0 == __FILE__

markdown = <<-__
* one
* two
* <%= :three %>
* <%= @x %>

```rb
@a = 42
yield
```
__

template = Tilt['md.erb'].new{ markdown  }

object = Object.new.instance_eval{ @x = :four; self }

puts template.render(object)

end
