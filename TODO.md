todo:

  - reconsider using active_model...

  - with ro, do we/should we need to expand assets?
    - posts
    -   body.md -> html -> expand_asset_urls?

  - https://github.com/rails/rails/blob/master/activemodel/lib/active_model/model.rb

  - track where shit comes from...

  - custom ui better?
    - chiclets
    - posts

done:

- expand relative asset links in html

- patch based transactions

  - http://ariejan.net/2009/10/26/how-to-create-and-apply-a-patch-with-git/

  - git checkout -b test-branch
  - add, commit, etc
    - add assets last

  - git format-patch master --stdout > p.patch

  - actor.date.uuid

  - 
    a:~/git/ahoward/ro $ git apply --stat p.patch
     tmp/coat.zip |  Bin
     tmp/a.txt    |    1 +
     2 files changed, 1 insertion(+)

  - git apply --check p.patch

  - git am --signoff < fix_empty_poster.patch

  - iff fail: sorry, your edits conflict with another user!
    - because they need to review new content ;-)

  - git branch -D test-branch
