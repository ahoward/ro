
Ro.root = '../sample_ro_data/'




node = ro.people[:ara]
html = node.bio


html = <<-__


  <a href='assets/ara-glacier.jpg'>barfoo</a>

  foobar

  42

__

puts Ro.expand_asset_urls(html, node)


__END__
root = Ro::Root.new('../sample_ro_data/')

patch =
  root.patch do
    #open('foo.txt', 'ab+'){|f| f.puts Time.now}

    p :go
    STDIN.gets
  end

p patch
puts
p 'patch.committed' => patch.committed
