
require("calabash").do "editor with tag",
  # "pkill -f doodle"
  "jade -o build/ -wP layout/index.jade"
  "stylus -o build/ -w layout/"
  "coffee -o lib/ -wbc -m coffee/"
  # "doodle build/ lib/"