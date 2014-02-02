module Ro
  module Pagination
    def paginate(*args)
      options = Map.options_for!(args)

      page = Integer(args.shift || options[:page] || 1)
      per = Integer(args.shift || options[:per] || options[:size] || 10)

      page = [page.abs, 1].max
      per = [per.abs, 1].max

      offset = (page - 1) * per
      length = per 

      slice = dup.slice(offset, length)
      slice.page = page
      slice.per = per
      slice.num_pages = (size.to_f / per).ceil
      slice
    end

    def page=(page)
      @page = page
    end

    def page(*args)
      @page
    end

    def current_page
      @page
    end

    def per=(per)
      @per = per
    end

    def per
      @per
    end

    def num_pages=(num_pages)
      @num_pages = num_pages
    end

    def num_pages
      @num_pages
    end

    def total_pages
      num_pages
    end
  end
end
