root = Ro::Root.new('../sample_ro_data/')

root.transaction do
  p 42
end
