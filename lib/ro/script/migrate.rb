module Ro
  class Script::Migrate
      def self.run!(script:)
        new(script: script).run!
      end

      attr_accessor :script

      def initialize(script:)
        @script = script
      end

      def run!
        parse_options!

        root_path = get_root_path

        show_banner(root_path)

        migrator = Ro::Migrator.new(root_path, @options)

        validate_and_report(migrator)

        return if @options[:dry_run]

        confirm_unless_forced!

        execute_migration(migrator)
      end

      private

      def parse_options!
        @options = {
          dry_run: false,
          backup: true,
          verbose: false,
          force: false
        }

        # Use ARGV directly because the Ro.script DSL may have consumed flags
        # We need to find 'migrate' in ARGV and parse everything after it
        argv = []
        found_migrate = false
        ARGV.each do |arg|
          if arg == 'migrate'
            found_migrate = true
            next
          end
          argv << arg if found_migrate
        end

        while argv.any?
          arg = argv.shift
          case arg
          when '-d', '--dry-run'
            @options[:dry_run] = true
            @options[:verbose] = true
          when '-b', '--backup'
            @options[:backup] = true
          when '--no-backup'
            @options[:backup] = false
          when '-v', '--verbose'
            @options[:verbose] = true
          when '-f', '--force'
            @options[:force] = true
          when '-h', '--help'
            show_help
            exit 0
          else
            argv.unshift(arg)
            break
          end
        end

        @script.argv.replace(argv)
      end

      def get_root_path
        if @script.argv.any?
          Pathname.new(@script.argv.first).expand_path
        else
          Ro.config.root.expand
        end
      end

      def show_banner(root_path)
        puts "Ro Asset Structure Migration Tool"
        puts "=" * 50
        puts "Root: #{root_path}"
        puts "Options: #{@options.inspect}" if @options[:verbose]
        puts ""
      end

      def validate_and_report(migrator)
        puts "Validating structure..."
        validation = migrator.validate

        puts "Collections found: #{validation[:collections].size}"
        puts "Old structure nodes: #{validation[:old_nodes].size}"
        puts "New structure nodes: #{validation[:new_nodes].size}"
        puts ""

        if validation[:old_nodes].empty?
          puts "✓ No old structure nodes found - migration not needed"
          exit 0
        end

        if validation[:has_new_structure]
          if @options[:force]
            puts "⚠ Warning: Both old and new structures detected!"
            puts "Proceeding with partial migration (--force enabled)..."
            puts ""
          else
            puts "⚠ Warning: Both old and new structures detected!"
            puts "This may indicate a partial migration."
            puts "Use --force to proceed anyway, or check your data first."
            exit 1
          end
        end

        if @options[:dry_run] || @options[:verbose]
          show_preview(migrator)
        end

        if @options[:dry_run]
          puts "✓ Dry run complete - no changes made"
          exit 0
        end
      end

      def show_preview(migrator)
        puts "Migration plan:"
        puts "-" * 50
        plan = migrator.preview
        plan.each_with_index do |step, i|
          puts "\n#{i + 1}. #{step[:collection]}/#{step[:node_id]}"
          step[:actions].each do |action|
            puts "   - #{action}"
          end
        end
        puts ""
      end

      def confirm_unless_forced!
        return if @options[:force]

        print "Proceed with migration? [y/N] "
        response = STDIN.gets.chomp
        unless response.downcase == 'y'
          puts "Migration cancelled"
          exit 0
        end
      end

      def execute_migration(migrator)
        puts "\nStarting migration..."
        result = migrator.migrate

        if result[:success]
          puts "\n✓ Migration complete!"
          puts "  Nodes migrated: #{result[:nodes_migrated]}"
          puts "  Collections migrated: #{result[:collections_migrated]}"

          if @options[:backup]
            puts "\n  Backup created - rollback available if needed"
          end
        else
          puts "\n✗ Migration failed"
          exit 1
        end
      end

      def show_help
        puts <<~HELP
          Usage: ro migrate [options] [ROOT_PATH]

          Migrates Ro assets from old structure to new simplified structure

          Options:
            -d, --dry-run           Preview migration without making changes
            -b, --[no-]backup       Create backup before migrating (default: true)
            -v, --verbose           Show detailed progress
            -f, --force             Force migration even if new structure detected
            -h, --help              Show this help message

          Examples:
            # Preview migration
            ro migrate --dry-run

            # Migrate with backup (default)
            ro migrate

            # Migrate without backup
            ro migrate --no-backup

            # Force migration in mixed structure
            ro migrate --force

          See MIGRATION.md for more details.
        HELP
      end
  end
end
