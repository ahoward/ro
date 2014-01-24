module Ro
  class Git
    attr_accessor :root
    attr_accessor :branch
    attr_accessor :in_transaction

    def initialize(root, options = {})
      options = Map.for(options)

      @root = root
      @branch = options[:branch] || 'master'
    end

# TODO - needs to be a submodule?
#
    def transaction(*args, &block)
      options = Map.options_for!(args)

      user = options[:user] || ENV['USER'] || 'ro'

      Thread.exclusive do
        @root.lock do
          Dir.chdir(@root) do
            # .git
            #
              status, stdout, stderr = spawn("git rev-parse --git-dir", :raise => true, :capture => true)

              git_root = stdout.to_s.strip

              dot_git = File.expand_path(git_root)

#p Dir.pwd
#p :git_root => git_root
#p :dot_git => dot_git

              unless test(?d, dot_git)
                raise Error.new("missing .git directory #{ dot_git }")
              end

            # calculate a branch name
            #
              time = Coerce.time(options[:time] || Time.now).utc.iso8601(2).gsub(/[^\w]/, '')
              branch = "#{ user }-#{ time }-#{ rand.to_s.gsub(/^0./, '') }"

              p branch
          end
        end
      end
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
        # .git
        #
          git_root = `git rev-parse --git-dir`.strip

          if git_root.empty?
            git_root = '.'
          end

          dot_git = File.expand_path(File.join(git_root, '.git'))

          unless test(?d, dot_git)
            raise Error.new("missing .git directory #{ dot_git }")
          end

        # correct branch
        #
          spawn("git checkout #{ @branch.inspect }", :raise => true)

        # return if nothing to do...
        #
          if `git status --porcelain`.strip.empty?
            return true
          end

        # commit the work
        #
          trying "to commit" do

            committed = 
              spawn("git add --all . && git commit -m #{ msg.inspect } -- .")

=begin
            unless committed
              spawn "git reset --hard"
            end
=end

#require 'pry'
#binding.pry
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
          end


          trying "to push" do
            pushed = nil

            unless spawn("git push")
            # merge
            #
              unless spawn("git pull")
                spawn("git checkout --ours -- .")
                spawn("git add --all .")
                spawn("git commit -F #{ dot_git }/MERGE_MSG")
              else
                raise 'wtf!?'
              end

              pushed = spawn("git push")
            else
              pushed = true
            end

            pushed
          end

=begin
  git push

    git pull

      # publish
      git checkout --ours -- .
      git add --all .
      git commit -F .git/MERGE_MSG
      git push
=end



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

      Ro.log(:debug, "command: #{ command }")
      Ro.log(:debug, "status: #{ status }")
      Ro.log(:debug, "stdout:\n#{ stdout }")
      Ro.log(:debug, "stderr:\n#{ stderr }")

      if options[:raise] == true
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
