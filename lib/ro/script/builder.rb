module Ro
  class Script::Builder
    class << self
      def run!(...)
        new(...).run!
      end
    end

    attr_reader :script

    def initialize(script:)
      @script = script
    end

    def run!
      @url = Ro.config.url
      @root = Ro.config.root
      @directory = Ro.config.build_directory
      @page_size = Ro.config.page_size
      @collections = Ro.root.collections.sort_by(&:name)

      @build = {}
      @nodes = []

      @started_at = Time.now.to_f
      @finished_at = nil
      @elapsed = nil

      # for all node collections...
      #
      @collections.each do |collection|
        type = collection.type
        name = collection.name
        sorted = collection.to_a.sort

        count = sorted.size
        last = count - 1
        page_count = (count / @page_size.to_f).ceil
        paginator = paginator_for(page_count, @page_size)

        sorted.each_with_index do |node, index|
          # track all nodes
          #
          @nodes << node

          # enhance with links to next/prev
          #
          rel = rel_for(sorted, index)
          node.attributes[:_meta][:rel] = rel

          # node data
          #
          data = data_for(node)
          _meta = meta_for(type: collection.type, id: node.id)
          path = "#{collection.type}/#{node.id}/index.json"
          @build[path] = { data:, _meta: }

          # paginate data
          #
          paginator[:data].push(node)
          generate_page = ((paginator[:data].size == paginator[:size]) || (index == last))
          next unless generate_page

          page = page_for(paginator)
          data = data_for(paginator[:data])
          _meta = meta_for(type: collection.type, page:)
          path = "#{collection.type}/index/#{page[:index]}.json" # eg. posts/index/$page.json
          @build[path] = { data:, _meta: }

          paginator[:data].clear
          paginator[:index] += 1
        end

        data = data_for(sorted)
        _meta = meta_for(type: collection.type)
        path = "#{collection.type}/index.json" # eg. posts/index.json
        @build[path] = { data:, _meta: }
      end

      # annnnd for all nodes...
      #
      count = @nodes.size
      last = count - 1
      page_count = (count / @page_size.to_f).ceil
      paginator = paginator_for(page_count, @page_size)

      @nodes.each_with_index do |node, index|
        # enhance with links to next/prev
        #
        rel = rel_for(@nodes, index)
        node.attributes[:_meta][:rel] = rel

        paginator[:data].push(node)
        should_generate_page = ((paginator[:data].size == paginator[:size]) || (index == last))
        next unless should_generate_page

        types = paginator[:data].map(&:type).sort.uniq
        page = page_for(paginator)
        data = data_for(paginator[:data])
        _meta = meta_for(types:, page:)

        path = "index/#{page[:index]}.json" # eg. index/$page.json
        @build[path] = { data:, _meta: }

        paginator[:data].clear
        paginator[:index] += 1
      end

      # index.json
      #
      types = @collections.map(&:type).sort
      data = data_for(@nodes)
      _meta = meta_for(types:)
      path = 'index.json'
      @build[path] = { data:, _meta: }

      # now output the build
      #
      script.say("ro.build: #{@root} -> #{@directory}", color: :magenta)
      FileUtils.rm_rf(@directory)

      FileUtils.cp_r(@root, @directory)
      Ro::Path.for(@directory).glob('**/**') do |entry|
        next unless test('f', entry)

        script.say("ro.build: #{entry}", color: :blue)
      end

      @build.each do |subpath, data|
        path = Ro::Path.for(@directory, subpath)
        script.say("ro.build: #{path}", color: :yellow)
        Ro.error! "#{path} would be clobbered" if path.exist?
        path.binwrite(JSON.pretty_generate(data))
      end

      # show stats
      #
      @finished_at = Time.now.to_f
      @elapsed = (@finished_at - @started_at).round(2)

      script.say("ro.build: #{@root} -> #{@directory} in #{@elapsed}s", color: :green)
    end

    def global_meta
      { url: @url }
    end

    def meta_for(meta)
      global_meta.merge(meta)
    end

    def rel_for(list, index)
      { curr: list[index].identifier, prev: nil, next: nil }.tap do |rel|
        rel[:prev] = list[index - 1].identifier if (index - 1) >= 0
        rel[:next] = list[index + 1].identifier if (index + 1) <= (list.size - 1)
      end
    end

    def paginator_for(count, size)
      {
        count:,
        size:,
        first: 0,
        last: count - 1,
        index: 0,
        data: []
      }
    end

    def page_for(paginator)
      paginator.except(:data).merge(
        {
          curr: paginator[:index],
          prev: ((paginator[:index] - 1) >= paginator[:first] ? (paginator[:index] - 1) : nil),
          next: ((paginator[:index] + 1) <= paginator[:last] ? (paginator[:index] + 1) : nil)
        }
      )
    end

    def data_for(value)
      {}.tap do |hash|
        case value
        when Array
          value.each { |node| hash.update(data_for(node)) }
        when Ro::Node
          hash[value.identifier] = value.to_hash
        else
          raise ArgumentError, "#{value.class}(#{value.inspect})"
        end
      end
    end
  end
end
