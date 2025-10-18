module Ro
  class Migrator
    attr_reader :root_path, :options

    def initialize(root_path, options = {})
      @root_path = Path.for(root_path)
      @options = {
        dry_run: false,
        backup: false,
        verbose: false,
        force: false
      }.merge(options)
    end

    def dry_run?
      @options[:dry_run]
    end

    def backup?
      @options[:backup]
    end

    def verbose?
      @options[:verbose]
    end

    def force?
      @options[:force]
    end

    # Validate the structure and return analysis
    def validate
      result = {
        has_old_structure: false,
        has_new_structure: false,
        old_nodes: [],
        new_nodes: [],
        collections: []
      }

      root = Root.for(@root_path)

      root.collections.each do |collection|
        collection_name = collection.name
        result[:collections] << collection_name

        # Check for new structure (metadata files at collection level)
        collection.metadata_files.each do |metadata_file|
          node_id = metadata_file.basename.to_s.sub(/\.(yml|yaml|json|toml)$/, '')
          result[:new_nodes] << {
            collection: collection_name,
            node_id: node_id,
            metadata_file: metadata_file
          }
          result[:has_new_structure] = true
        end

        # Check for old structure (subdirectories with attributes.yml)
        collection.subdirectories.each do |subdir|
          attributes_file = subdir.join('attributes.yml')
          if attributes_file.exist?
            result[:old_nodes] << {
              collection: collection_name,
              node_id: subdir.basename.to_s,
              old_path: subdir
            }
            result[:has_old_structure] = true
          end
        end
      end

      result
    end

    # Preview migration without making changes
    def preview
      validation = validate
      plan = []

      validation[:old_nodes].each do |old_node|
        collection_name = old_node[:collection]
        node_id = old_node[:node_id]
        old_path = old_node[:old_path]

        collection_path = @root_path.join(collection_name)
        new_metadata_file = collection_path.join("#{node_id}.yml")
        new_asset_dir = collection_path.join(node_id)

        plan << {
          node_id: node_id,
          collection: collection_name,
          old_path: old_path,
          new_metadata_file: new_metadata_file,
          new_asset_dir: new_asset_dir,
          actions: [
            "Move #{old_path}/attributes.yml → #{new_metadata_file}",
            "Move #{old_path}/assets/* → #{new_asset_dir}/",
            "Remove #{old_path}/assets/",
            "Remove #{old_path}/ (if empty)"
          ]
        }
      end

      plan
    end

    # Migrate a single node
    def migrate_node(collection_name, node_id)
      log "Migrating #{collection_name}/#{node_id}..."

      collection_path = @root_path.join(collection_name)
      old_node_path = collection_path.join(node_id)

      unless old_node_path.directory?
        return { success: false, error: "Node directory not found: #{old_node_path}" }
      end

      old_attributes_file = old_node_path.join('attributes.yml')
      unless old_attributes_file.exist?
        return { success: false, error: "attributes.yml not found: #{old_attributes_file}" }
      end

      new_metadata_file = collection_path.join("#{node_id}.yml")
      new_asset_dir = collection_path.join(node_id)
      old_assets_dir = old_node_path.join('assets')

      # Move attributes.yml to collection level
      unless dry_run?
        log "  Moving #{old_attributes_file} → #{new_metadata_file}"
        FileUtils.mv(old_attributes_file.to_s, new_metadata_file.to_s)
      end

      # Move assets from assets/ subdirectory to node directory
      if old_assets_dir.exist?
        old_assets_dir.glob('*') do |asset_file|
          target_path = new_asset_dir.join(asset_file.basename)
          unless dry_run?
            log "  Moving #{asset_file} → #{target_path}"
            FileUtils.mv(asset_file.to_s, target_path.to_s)
          end
        end

        # Remove old assets/ directory
        unless dry_run?
          log "  Removing #{old_assets_dir}"
          FileUtils.rm_rf(old_assets_dir.to_s)
        end
      end

      { success: true, node_id: node_id }
    end

    # Migrate an entire collection
    def migrate_collection(collection_name)
      log "Migrating collection: #{collection_name}"

      validation = validate
      collection_nodes = validation[:old_nodes].select { |n| n[:collection] == collection_name }

      migrated_count = 0
      errors = []

      collection_nodes.each do |old_node|
        result = migrate_node(collection_name, old_node[:node_id])
        if result[:success]
          migrated_count += 1
        else
          errors << result[:error]
        end
      end

      {
        success: errors.empty?,
        migrated_count: migrated_count,
        errors: errors
      }
    end

    # Migrate entire root
    def migrate
      log "Starting full migration of #{@root_path}"

      if backup?
        backup_path = backup
        log "Created backup at #{backup_path}"
      end

      validation = validate

      if validation[:old_nodes].empty?
        log "No old structure nodes found to migrate"
        return { success: true, nodes_migrated: 0, collections_migrated: 0 }
      end

      collections = validation[:old_nodes].map { |n| n[:collection] }.uniq
      total_migrated = 0
      collections_migrated = 0

      collections.each do |collection_name|
        result = migrate_collection(collection_name)
        if result[:success]
          collections_migrated += 1
          total_migrated += result[:migrated_count]
        end
      end

      log "Migration complete! Migrated #{total_migrated} nodes across #{collections_migrated} collections"

      {
        success: true,
        nodes_migrated: total_migrated,
        collections_migrated: collections_migrated
      }
    end

    # Create backup
    def backup
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
      backup_name = "#{@root_path.basename}.backup.#{timestamp}"
      backup_path = @root_path.parent.join(backup_name)

      log "Creating backup: #{backup_path}"

      unless dry_run?
        FileUtils.cp_r(@root_path.to_s, backup_path.to_s)
      end

      backup_path
    end

    # Rollback from backup
    def rollback
      # Find most recent backup
      backup_pattern = "#{@root_path.basename}.backup.*"
      backups = @root_path.parent.glob(backup_pattern).sort.reverse

      if backups.empty?
        return { success: false, error: "No backups found" }
      end

      backup_path = backups.first
      log "Rolling back from #{backup_path}"

      unless dry_run?
        # Remove current root
        FileUtils.rm_rf(@root_path.to_s)
        # Restore from backup
        FileUtils.cp_r(backup_path.to_s, @root_path.to_s)
      end

      {
        success: true,
        restored_from: backup_path
      }
    end

    private

    def log(message)
      puts message if verbose? || dry_run?
    end
  end
end
