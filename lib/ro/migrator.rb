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

        # Check for old structure (ALL subdirectories, with or without attributes)
        # We need to migrate ALL nodes, even those without attributes.yml
        collection.subdirectories.each do |subdir|
          node_id = subdir.basename.to_s

          # Skip if this node already has new-structure metadata
          already_migrated = result[:new_nodes].any? { |n|
            n[:collection] == collection_name && n[:node_id] == node_id
          }
          next if already_migrated

          # Check if there's an attributes file (any format)
          attributes_file = nil
          has_attributes = false
          %w[yml yaml json toml].each do |ext|
            candidate = subdir.join("attributes.#{ext}")
            if candidate.exist?
              attributes_file = candidate
              has_attributes = true
              break
            end
          end

          result[:old_nodes] << {
            collection: collection_name,
            node_id: node_id,
            old_path: subdir,
            attributes_file: attributes_file,
            has_attributes: has_attributes
          }
          result[:has_old_structure] = true
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
        has_attributes = old_node[:has_attributes]
        attributes_file = old_node[:attributes_file]

        collection_path = @root_path.join(collection_name)
        new_metadata_file = collection_path.join("#{node_id}.yml")
        new_asset_dir = collection_path.join(node_id)

        actions = []
        if has_attributes
          actions << "Move #{attributes_file} → #{new_metadata_file}"
        else
          actions << "Create empty #{new_metadata_file} (node has no attributes)"
        end
        actions << "Assets remain in #{old_path}/assets/ (no change needed)"

        plan << {
          node_id: node_id,
          collection: collection_name,
          old_path: old_path,
          new_metadata_file: new_metadata_file,
          new_asset_dir: new_asset_dir,
          has_attributes: has_attributes,
          actions: actions
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

      new_metadata_file = collection_path.join("#{node_id}.yml")

      # Look for attributes file in any format
      old_attributes_file = nil
      %w[yml yaml json toml].each do |ext|
        candidate = old_node_path.join("attributes.#{ext}")
        if candidate.exist?
          old_attributes_file = candidate
          break
        end
      end

      unless dry_run?
        if old_attributes_file
          # Move existing attributes file to collection level
          log "  Moving #{old_attributes_file} → #{new_metadata_file}"
          FileUtils.mv(old_attributes_file.to_s, new_metadata_file.to_s)
        else
          # Create empty metadata file for nodes without attributes
          log "  Creating empty metadata #{new_metadata_file} (node had no attributes)"
          File.write(new_metadata_file.to_s, {}.to_yaml)
        end
      end

      # Assets stay in assets/ subdirectory - no moving needed
      # Old: collection/identifier/assets/foo.png
      # New: collection/identifier/assets/foo.png (same location)

      { success: true, node_id: node_id, had_attributes: !old_attributes_file.nil? }
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
