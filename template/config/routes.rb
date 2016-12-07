Cthulhu.routes do

  # syntax:
  # route 'routing.key' => 'ExampleHandler#action'
  # Topic routes syntax:
  # '*' (star) can substitute for exactly one word.
  # '#' (hash) can substitute for zero or more words.
  # Examples:
  # route '#' ... will match anything. Use it for catch all
  # route '*' ... will match any single word
  # route 'order.*' ... will match anything starting with 'order.' followed by another word
  # route 'order.#' ... will match 'order' or 'order' followed by multiple words

  # Common mistakes:
  # route '#.foo' DOES NOT MAKE SENSE
  # route '#.*' DOES NOT MAKE SENSE
  # route 'foo.#.*' DOES NOT MAKE SENSE
  # route 'foo.*.#' DOES NOT MAKE SENSE, since it will accept anything preceeded by 'foo.'




end
