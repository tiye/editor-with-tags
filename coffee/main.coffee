
duplicate = (string , times) ->
  output = ""
  [1..times].forEach -> output += string
  output

$ ->
  console.log "started"

  demo = new EditorWithTags

  console.log demo

  $("#target").prepend demo.elem
  demo.text duplicate "demo for test", 3
  demo.renderMenu [
    "a"
    "b"
  ]

  demo.keydown -> console.log "keydown"
  demo.keyup ->

  console.log demo instanceof EditorWithTags