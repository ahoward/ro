

p Ro

Ro.root = File.join(File.expand_path(File.dirname(__FILE__)), 'db')

p Ro.root

p Ro.db

p Ro.db.collections

p Ro.db.nodes

p ro

node = ro.first

p node

p node.title
p node.published_at

__END__


p ro


p ro.posts

p ro.posts.related(:tags)

post = ro.posts.first

p post.related(:tags)
