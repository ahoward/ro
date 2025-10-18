# Quickstart: Simplify Asset Directory Structure

**Feature**: 001-simplify-asset-structure
**Version**: 5.0.0
**Date**: 2025-10-17

## Overview

This guide walks you through migrating from the old nested asset structure to the new simplified structure, and demonstrates how to use the new API.

## For Existing Users: Migration Guide

### Step 1: Backup Your Data

Before migrating, create a backup of your ro directory:

```bash
cp -r ./public/ro ./public/ro.backup
```

### Step 2: Validate Your Structure

Check if your assets are in the old format:

```bash
# Look for the old pattern:
find ./public/ro -name "attributes.yml" -o -name "attributes.yaml"

# If you see results like:
# ./public/ro/posts/my-post/attributes.yml
# ./public/ro/pages/about/attributes.yml
# Then you have the old structure and need to migrate.
```

### Step 3: Run Migration (Dry Run First)

Preview the migration without making changes:

```bash
ro migrate ./public/ro --dry-run --verbose
```

Review the output to ensure it looks correct:

```
[DRY RUN] Migrating collection: posts
[DRY RUN]   Node: my-post
[DRY RUN]     MOVE: posts/my-post/attributes.yml → posts/my-post.yml
[DRY RUN]     MOVE: posts/my-post/assets/cover.jpg → posts/my-post/cover.jpg
[DRY RUN]     MOVE: posts/my-post/body.md → posts/my-post/body.md
[DRY RUN]     REMOVE: posts/my-post/assets/ (empty)
[DRY RUN]   Node: another-post
[DRY RUN]     ...
[DRY RUN] Summary: 15 nodes would be migrated
```

### Step 4: Run Actual Migration

If the dry run looks good, run the real migration with backup:

```bash
ro migrate ./public/ro --backup --verbose
```

Output:

```
Creating backup at: ./public/ro.backup.20250117-143022
Migrating collection: posts
  ✓ my-post migrated successfully
  ✓ another-post migrated successfully
  ✓ ...
Migrating collection: pages
  ✓ about migrated successfully
  ✓ ...
✓ Migration complete!
  Total nodes: 15
  Migrated: 15
  Failed: 0
  Backup: ./public/ro.backup.20250117-143022
```

### Step 5: Verify Migration

Check that your assets are now in the new format:

```bash
# Look for the new pattern:
ls -la ./public/ro/posts/

# You should see:
# my-post.yml           ← Metadata at collection level
# my-post/              ← Asset directory (no more assets/ subdirectory)
#   ├── body.md
#   └── cover.jpg
```

Test that the ro gem can load your assets:

```bash
ro console
```

```ruby
root = Ro::Root.new('./public/ro')
posts = root.collection('posts')
post = posts.node_for('my-post')

puts post.attributes[:title]  # Should print the title
puts post.asset_paths          # Should show cover.jpg, etc.
```

### Step 6: Remove Old Backup (Optional)

Once you've verified everything works, you can remove the old backup:

```bash
rm -rf ./public/ro.backup.20250117-143022
```

---

## For New Users: Using the New Structure

### Creating a New ro Directory

```bash
mkdir -p ./my-ro/posts
cd ./my-ro
```

### Creating Your First Asset

Create a metadata file at the collection level:

**posts/my-first-post.yml**:
```yaml
title: "My First Post"
author: "Your Name"
published_at: 2025-01-17
tags:
  - tutorial
  - ro
```

Create the asset directory and add files:

```bash
mkdir posts/my-first-post
echo "# Hello World" > posts/my-first-post/body.md
cp ~/cover-image.jpg posts/my-first-post/cover.jpg
```

Your structure should look like:

```
my-ro/
└── posts/
    ├── my-first-post.yml       ← Metadata
    └── my-first-post/          ← Assets
        ├── body.md
        └── cover.jpg
```

### Loading Assets with the ro Gem

```ruby
require 'ro'

root = Ro::Root.new('./my-ro')
posts = root.collection('posts')

# Get a specific post
post = posts.node_for('my-first-post')

# Access metadata
puts post[:title]           # => "My First Post"
puts post[:author]          # => "Your Name"
puts post.attributes        # => { title: "My First Post", ... }

# Access assets
post.asset_paths.each do |asset_path|
  puts asset_path  # => .../posts/my-first-post/body.md
               # => .../posts/my-first-post/cover.jpg
end

# Iterate all posts
posts.each do |post|
  puts "#{post.id}: #{post[:title]}"
end
```

---

## Common Workflows

### Workflow 1: Adding a New Post (Programmatic)

```ruby
require 'ro'
require 'fileutils'
require 'yaml'

root = Ro::Root.new('./my-ro')
posts = root.collection('posts')

# Define new post ID and metadata
post_id = 'my-new-post'
metadata = {
  title: "My New Post",
  author: "Your Name",
  published_at: Date.today.to_s,
  tags: ['ruby', 'gems']
}

# Create metadata file
metadata_file = posts.path / "#{post_id}.yml"
File.write(metadata_file, metadata.to_yaml)

# Create asset directory and add files
asset_dir = posts.path / post_id
FileUtils.mkdir_p(asset_dir)

body_content = "# My New Post\n\nThis is the content."
File.write(asset_dir / 'body.md', body_content)

# Verify
node = posts.node_for(post_id)
puts node[:title]  # => "My New Post"
```

### Workflow 2: Updating Post Metadata

```ruby
require 'ro'

root = Ro::Root.new('./my-ro')
post = root.collection('posts').node_for('my-first-post')

# Update attributes
post.update_attributes!(
  title: "Updated Title",
  tags: post[:tags] + ['updated']
)

# Reload to verify
updated_post = root.collection('posts').node_for('my-first-post')
puts updated_post[:title]  # => "Updated Title"
```

### Workflow 3: Adding Assets to Existing Post

```ruby
require 'ro'
require 'fileutils'

root = Ro::Root.new('./my-ro')
post = root.collection('posts').node_for('my-first-post')

# Copy a new image to the post's asset directory
source_image = './new-diagram.png'
dest_image = post.asset_dir / 'diagram.png'
FileUtils.cp(source_image, dest_image)

# Verify
puts post.asset_paths.map(&:basename)  # => ["body.md", "cover.jpg", "diagram.png"]
```

### Workflow 4: Listing All Posts with Assets

```ruby
require 'ro'

root = Ro::Root.new('./my-ro')
posts = root.collection('posts')

posts.each do |post|
  puts "Post: #{post[:title]}"
  puts "  ID: #{post.id}"
  puts "  Assets: #{post.asset_paths.size} files"
  post.asset_paths.each do |asset|
    puts "    - #{asset.basename}"
  end
  puts
end
```

---

## Integration Scenarios

### Scenario 1: Building a Static Site

```ruby
require 'ro'
require 'json'
require 'fileutils'

# Load ro data
root = Ro::Root.new('./content')
posts = root.collection('posts')

# Build static JSON API
api_dir = './public/api'
FileUtils.mkdir_p(api_dir)

# Generate index
index = posts.map do |post|
  {
    id: post.id,
    title: post[:title],
    author: post[:author],
    published_at: post[:published_at],
    url: "/posts/#{post.id}"
  }
end
File.write("#{api_dir}/posts.json", JSON.pretty_generate(index))

# Generate individual post files
posts.each do |post|
  post_data = {
    id: post.id,
    attributes: post.attributes,
    assets: post.asset_paths.map { |p| "/assets/#{post.id}/#{p.basename}" }
  }

  post_dir = "#{api_dir}/posts"
  FileUtils.mkdir_p(post_dir)
  File.write("#{post_dir}/#{post.id}.json", JSON.pretty_generate(post_data))

  # Copy assets
  asset_dest_dir = "./public/assets/#{post.id}"
  FileUtils.mkdir_p(asset_dest_dir)
  post.asset_paths.each do |asset|
    FileUtils.cp(asset, asset_dest_dir / asset.basename)
  end
end

puts "Static site built in ./public"
```

### Scenario 2: Markdown Blog Integration

```ruby
require 'ro'
require 'kramdown'

root = Ro::Root.new('./blog')
posts = root.collection('posts')

# Render posts to HTML
posts.each do |post|
  # Read markdown body
  body_path = post.asset_dir / 'body.md'
  next unless body_path.exist?

  markdown = File.read(body_path)

  # Render to HTML
  html = Kramdown::Document.new(markdown, input: 'GFM').to_html

  # Combine with metadata
  output = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>#{post[:title]}</title>
      <meta name="author" content="#{post[:author]}">
    </head>
    <body>
      <h1>#{post[:title]}</h1>
      <p>By #{post[:author]} on #{post[:published_at]}</p>
      #{html}
    </body>
    </html>
  HTML

  # Write HTML file
  html_dir = './output/posts'
  FileUtils.mkdir_p(html_dir)
  File.write("#{html_dir}/#{post.id}.html", output)
end

puts "Blog rendered to ./output/posts"
```

### Scenario 3: API Server with Sinatra

```ruby
require 'sinatra'
require 'ro'
require 'json'

# Initialize ro
set :ro_root, Ro::Root.new('./content')

# List all posts
get '/api/posts' do
  content_type :json
  posts = settings.ro_root.collection('posts')

  posts.map do |post|
    {
      id: post.id,
      title: post[:title],
      author: post[:author],
      url: "/api/posts/#{post.id}"
    }
  end.to_json
end

# Get single post
get '/api/posts/:id' do
  content_type :json
  posts = settings.ro_root.collection('posts')
  post = posts.node_for(params[:id])

  halt 404, { error: 'Not found' }.to_json unless post

  {
    id: post.id,
    attributes: post.attributes,
    assets: post.asset_paths.map { |p| "/assets/#{post.id}/#{p.basename}" }
  }.to_json
end

# Serve assets
get '/assets/:post_id/:filename' do
  posts = settings.ro_root.collection('posts')
  post = posts.node_for(params[:post_id])

  halt 404 unless post

  asset = post.asset_dir / params[:filename]
  halt 404 unless asset.exist?

  send_file asset
end
```

---

## Troubleshooting

### Issue: "Metadata file not found"

**Symptom**: `collection.node_for('my-post')` returns `nil`

**Cause**: Metadata file doesn't exist or has wrong extension

**Solution**:
```bash
# Check if metadata file exists
ls ./my-ro/posts/my-post.yml

# If not, create it:
cat > ./my-ro/posts/my-post.yml <<EOF
title: "My Post"
EOF
```

### Issue: "No assets found"

**Symptom**: `node.asset_paths` is empty

**Cause**: Asset directory doesn't exist

**Solution**:
```bash
# Create asset directory
mkdir ./my-ro/posts/my-post

# Add files
echo "# Content" > ./my-ro/posts/my-post/body.md
```

### Issue: "Migration failed partway through"

**Symptom**: Some nodes migrated, some didn't

**Solution**:
```bash
# Check migration log for errors
cat ./migration.log

# If safe, re-run migration (will skip already-migrated nodes)
ro migrate ./public/ro --verbose

# Or rollback to backup:
ro migrate --rollback ./public/ro.backup.20250117-143022
```

### Issue: "Both old and new structures exist"

**Symptom**: Migration warnings about duplicate structures

**Solution**:
```bash
# The new structure takes precedence in v5.0
# Manually remove old structure if migration completed:
rm -rf ./public/ro/posts/my-post/attributes.yml
rm -rf ./public/ro/posts/my-post/assets/
```

---

## Best Practices

### 1. Metadata Naming

Use kebab-case for post IDs:
- ✓ `my-first-post.yml`
- ✗ `My First Post.yml` (spaces)
- ✗ `my_first_post.yml` (underscores okay but less common)

### 2. Asset Organization

Keep assets organized in subdirectories:
```
my-post/
├── body.md
├── images/
│   ├── hero.jpg
│   └── diagram.png
└── downloads/
    └── code-sample.zip
```

### 3. Metadata Format

Prefer YAML for human-edited metadata:
- YAML: Best for hand-editing (`.yml`)
- JSON: Best for programmatic generation (`.json`)
- TOML: Alternative (`.toml`, if supported)

### 4. Version Control

In `.gitignore`, track metadata and markdown, ignore generated files:
```gitignore
# Track these:
# *.yml
# *.md

# Ignore these:
public/api/
.backup.*
```

### 5. Backup Before Migration

Always create a backup before migrating:
```bash
# Timestamp your backups
cp -r ./ro "./ro.backup.$(date +%Y%m%d-%H%M%S)"
```

---

## What's Next?

- **Spec**: Read [spec.md](./spec.md) for full feature requirements
- **Implementation Plan**: See [plan.md](./plan.md) for technical architecture
- **Data Model**: Review [data-model.md](./data-model.md) for entity relationships
- **API Contracts**: Check [contracts/](./contracts/) for detailed API documentation
- **Tasks**: Execute [tasks.md](./tasks.md) for implementation checklist (after running `/speckit.tasks`)

---

## Version Info

**Feature Version**: 5.0.0 (breaking change from 4.x)
**Migration Required**: Yes (one-time, run `ro migrate`)
**Backward Compatibility**: No (major version bump)

For questions or issues, refer to the main ro gem documentation or file an issue on GitHub.
