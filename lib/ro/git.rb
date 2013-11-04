module Ro
  class Git
    attr_accessor :root
    attr_accessor :branch

    def initialize(root, options = {})
      options = Map.for(options)

      @root = root
      @branch = options[:branch] || 'master'
    end

    def save(directory, options = {})
      if directory.is_a?(Node)
        directory = directory.path
      end

      options = Map.for(options)

      dir = File.expand_path(directory.to_s)

      relative_path = Ro.relative_path(dir, :from => @root)

      exists = test(?d, dir)

      action = exists ? 'edited' : 'created'

      msg = options[:message] || "#{ ENV['USER'] } #{ action } #{ relative_path }"

      @root.lock do
        FileUtils.mkdir_p(dir) unless exists

        Dir.chdir(dir) do
        # correct branch
        #
          spawn "git checkout #{ @branch.inspect }"

        # commit the work
        #

          trying "to commit" do
            committed = false

require 'pry'
binding.pry
=begin
            retried = false
            begin
              spawn "git add --all . && git commit -m #{ msg.inspect } -- ."
              committed = true
            rescue
              raise if retried
              spawn "git reset --hard", :raise => false
              retry
            end
=end

            committed
          end
        end
      end
    end

    class Error < ::StandardError;end

    def trying(*args, &block)
      options = Map.options_for!(args)
      label = ['trying', *args].join(' - ')

      n = Integer(options[:n] || 3)
      timeout = options[:timeout]
      e = nil
      done = nil
      not_done = Object.new.freeze

      result =
        catch(:trying) do
          n.times do
            done = block.call
            if done
              throw(:trying, done)
            else
              unless timeout == false
                sleep(timeout || rand)
              end
            end
          end

          not_done
        end

      if result == not_done
        raise(Error.new("#{ label } failed #{ n } times"))
      else
        done
      end
    end

    def spawn(command, options = {})
      options = Map.for(options)

      status, stdout, stderr = systemu(command)

      unless options[:raise] == false
        unless status == 0
          raise "command (#{ command }) failed with #{ status }"
        end
      end

      if options[:capture]
        [status, stdout, stderr]
      else
        status == 0
      end
    end
  end
end
