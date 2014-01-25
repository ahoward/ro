module Ro
  class Git
    attr_accessor :root
    attr_accessor :branch
    attr_accessor :patching

    def initialize(root, options = {})
      options = Map.for(options)

      @root = root
      @branch = options[:branch] || 'master'
    end

  # patch takes a block, allows abitrary edits (additions, modifications,
  # deletions) to be performed by it, and then computes a single, atomic patch
  # that is applied to the repo and pushed.  the patch is returned.  if the
  # patch was not applied then patch.applied==false and it's up to client code
  # to decide how to proceed, perhaps retrying or saving the patchfile for
  # later manual application
  #
    def patch(*args, &block)
      options = Map.options_for!(args)

      user = options[:user] || ENV['USER'] || 'ro'
      msg = options[:message] || "#{ user } edits on #{ File.basename(@root).inspect }"

      patch = nil

      Thread.exclusive do
        @root.lock do
          Dir.chdir(@root) do
            # ensure .git-ness
            #
              status, stdout, stderr = spawn("git rev-parse --git-dir", :raise => true, :capture => true)

              git_root = stdout.to_s.strip

              dot_git = File.expand_path(git_root)

              unless test(?d, dot_git)
                raise Error.new("missing .git directory #{ dot_git }")
              end

            # calculate a tmp branch name
            #
              time = Coerce.time(options[:time] || Time.now).utc.iso8601(2).gsub(/[^\w]/, '')
              branch = "#{ user }-#{ time }-#{ rand.to_s.gsub(/^0./, '') }"

            # allow block to edit, compute the patch, attempt to apply it
            #
              begin
              # get pristine
              #
                spawn("git checkout -f master", :raise => true)
                spawn("git fetch --all", :raise => true)
                spawn("git reset --hard origin/master", :raise => true)

              # pull recent changes
              #
                trying('to pull'){ spawn("git pull") }

              # create a new temporary branch
              #
                spawn("git checkout -b #{ branch.inspect }", :raise => true)

              # the block can perform arbitrary edits
              #
                block.call

              # add all changes - additions, deletions, or modifications
              #
                spawn("git add . --all", :raise => true)

              # commit if anything changed
              #
                changes_to_apply =
                  spawn("git commit -am #{ msg.inspect }")

                if changes_to_apply
                # create the patch
                #
                  status, stdout, stderr =
                    spawn("git format-patch master --stdout", :raise => true, :capture => true)

                  patch = Patch.new(:data => stdout, :name => branch)

                  unless stdout.to_s.strip.empty?
                  # apply the patch
                  #
                    spawn("git checkout master", :raise => true)

                    status, stdout, stderr =
                      spawn("git am --signoff --3way", :capture => true, :stdin => patch.data)

                    patch.applied = !!(status == 0)

                  # commit the patch back to the repo
                  #
                    patch.committed =
                      begin
                        trying('to pull'){ spawn("git pull") }
                        trying('to push'){ spawn("git push") }
                        true
                      rescue Object
                        false
                      end
                  end
                end
              ensure
              # get pristine
              #
                spawn("git checkout -f master", :raise => true)
                spawn("git fetch --all", :raise => true)
                spawn("git reset --hard origin/master", :raise => true)

              # get changes
              #
                trying('to pull'){ spawn("git pull") }

              # nuke the tmp branch
              #
                spawn("git branch -D #{ branch.inspect }")
              end
          end
        end
      end

      patch
    end

  #
    class Patch
      fattr :data
      fattr :name
      fattr :applied
      fattr :committed
      fattr :status
      fattr :stdout
      fattr :stderr

      def initialize(*args)
        options = Map.options_for!(args)

        self.class.fattrs.each do |key|
          send(key, options.get(key)) if options.has?(key)
        end

        unless args.empty?
          self.data = args.join
        end
      end

      def save(path)
        return false unless data
        path = path.to_s
        FileUtils.mkdir_p(File.dirname(path))
        IO.binwrite(path, data)
      end

      %w( to_s to_str ).each do |method|
        class_eval <<-__, __FILE__, __LINE__
          def #{ method }
            data
          end
        __
      end

      %w( filename pathname basename ).each do |method|
        class_eval <<-__, __FILE__, __LINE__
          def #{ method }
            name
          end
        __
      end

      %w( success success? applied applied? ).each do |method|
        class_eval <<-__, __FILE__, __LINE__
          def #{ method }
            status && status == 0
          end
        __
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
          n.times do |i|
            done = block.call
            if done
              throw(:trying, done)
            else
              unless timeout == false
                sleep( (i + 1) * (timeout || (1 + rand)) )
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

      status, stdout, stderr = systemu(command, :stdin => options[:stdin])

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
