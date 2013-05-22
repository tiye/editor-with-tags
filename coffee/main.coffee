
duplicate = (string , times) ->
  output = ""
  [1..times].forEach -> output += string
  output

$ ->
  console.log "started"

  window.demo = demo = new EditorWithTags
  demo.loadSuggest
    "@": ["today", "torrow", "next week", "昨天", "今天", "明天"]
    "^": ["list a", "list b", "列表3", "列表 4"]

  console.log demo

  $("#target").prepend demo.elem

  # demo.keydown -> console.log "keydown"
  # demo.keyup -> console.log "keyup"

  console.log demo instanceof EditorWithTags

  demo.elem.find(".input").click()
  # demo.test()

  demo.placeholder "demo of placeholder"
  demo.setIcon "http://cdn1.iconfinder.com/data/icons/iconic/raster/12/arrow_down.png"

  demo.keydown (event) ->
    if event.keyCode is 13
      console.log demo.takeValue()
      event.preventDefault()
      off