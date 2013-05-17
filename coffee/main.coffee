
duplicate = (string , times) ->
  output = ""
  [1..times].forEach -> output += string
  output

$ ->
  console.log "started"

  demo = new EditorWithTags
  demo.suggest
    "@": ["today", "torrow", "next week", "昨天", "今天", "明天"]
    "^": ["list a", "list b", "列表3", "列表 4"]

  console.log demo

  $("#target").prepend demo.elem

  # demo.keydown -> console.log "keydown"
  # demo.keyup -> console.log "keyup"

  console.log demo instanceof EditorWithTags

  demo.elem.find(".input").click()
  # demo.test()