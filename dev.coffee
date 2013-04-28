require("calabash").run [
  "pkill -f doodle"
  "jade -o build/ -wP layout/index.jade"
  "stylus -o build/ -w layout/"
  "coffee -o lib/ -wbc coffee/"
  "doodle build/ lib/"
]