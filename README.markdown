# RailsBuffer

> execute selected ruby in your rails environment and return the result in a scratch buffer

### How To:

It's easy:
- Make sure the buffer has it's filetype set to ruby:
  - `:set ft=ruby`
- Visually select some ruby code, or don't and the whole file will be used
- `:RailsBuffer`
- Any writes to standard out, and the last line of your script will be put into a new scratch buffer
- Optionally map it to something sweet, like `map <leader>r :RailsBuffer <cr>`

### Rails Loads Slow

RailsBuffer will use a forking helper like zeus or spring.  Just define a variable in your `.vimrc` like:

```
let rails_buffer_helper='spring'  # for spring
let rails_buffer_helper='zeus'    # for zeus
```

### Example:

````
puts "I go to standard out"
class Nerd < ActiveRecord::Base
  belongs_to :cat
end

Nerd.new
````

Will create a new scratch buffer containing:

````
I go to standard out
#<Nerd id: nil, cat_id: nil, created_at: nil, updated_at: nil>
````
