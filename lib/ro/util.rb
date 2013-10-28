module Ro
  module Util
    def realpath(path)
      begin
        Pathname.new(path.to_s).expand_path.realpath.to_s
      rescue Object
        File.expand_path(path.to_s)
      end
    end

    extend(self)
  end
end
