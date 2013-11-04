module Ro
  class Lock
    def initialize(path)
      @path = path.to_s
      @fd = false
    end

    def lock(&block)
      open!

      if block
        begin
          lock!
          block.call
        ensure
          unlock!
        end
      else
        self
      end
    end

    def open!
      @fd ||= (
        fd =
          begin
            open(@path, 'ab+')
          rescue
            unless test(?e, @path)
              FileUtils.mkdir_p(@path)
              FileUtils.touch(@path)
            end

            open(@path, 'ab+')
          end

        fd.close_on_exec = true

        fd
      )
    end

    def lock!
      open!
      @fd.flock File::LOCK_EX
    end

    def unlock!
      open!
      @fd.flock File::LOCK_UN
    end
  end
end
