module Ro
  class Template
    def Template.render(path, node = nil)
      parts = File.basename(path).split('.')
      base = parts.shift
      exts = parts.reverse

      content = IO.binread(path).force_encoding('utf-8')

      loop do
        break if exts.empty?
        ext = exts.shift

        case ext.to_s.downcase
          when 'erb', 'eruby'
            content = Ro.erb(content, node)
          when 'yml'
            content = YAML.load(content)
          else
            tilt = Tilt[ext] || Tilt['txt']

            if tilt.nil?
              content
            else
              content = tilt.new{ content }.render(node)
            end
        end
      end

      content
    end

    def Template.render_source(path, node = nil)
      parts = File.basename(path).split('.')
      base = parts.shift
      exts = parts.reverse

      content = IO.binread(path).force_encoding('utf-8')

      loop do
        break if exts.empty?
        ext = exts.shift

        if exts.empty?
          code = content
          language = ext
          content = 
            begin
              ::Pygments.highlight(code, :lexer => language, :options => {:encoding => 'utf-8'})
            rescue
              content
            end
        else
          case ext.to_s.downcase
            when 'erb', 'eruby'
              content = Ro.erb(content, node)
            when 'yml'
              content = YAML.load(content)
            else
              tilt = Tilt[ext].new{ content  }
              content = tilt.render(node)
          end
        end
      end

      content
    end

    fattr :path

    def initialize(path)
      @path = Ro.realpath(path)
    end
  end
end
