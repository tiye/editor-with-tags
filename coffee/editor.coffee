
EditorWithTags = (options) ->
  @options = options

  @elem = $("<div>").addClass "editor-with-tags"
  @input = $("<div>").addClass("input").attr "contenteditable", yes
  @menu = $("<div>").addClass("menu")
  @elem.append @input, @menu

  @elem.find(".input").append($(document.createTextNode("")))
  @elem.find(".input").append("<br>")

  @setupEvents()
  return

EditorWithTags:: =
  contructor: EditorWithTags

  text: (value) ->
    # @elem.find(".input").text value

  delay: (t, f) -> setTimeout (=> f()), t

  position:
    left: 0

  editable: (elem) ->
    elem.attr "contenteditable", yes

  setupEvents: ->

    @events = new EventEmitter

    @elem.on "focus", ".input", (event) => @focus event
    @elem.on "blur", ".input", (event) => @blur event
    @elem.on "keydown", ".input", (event) => @onkeydown event
    @elem.on "keyup", ".input", (event) => @onkeyup event
    @elem.on "click", ".input", (event) =>
      elem = $(event.target)
      # console.log "the elem to focus", elem
      elem[0].focus()

  focus: ->
    console.log "focus"
    @elem.addClass "focus"

  blur: ->
    @elem.removeClass "focus"

  onkeydown: (event) ->
    # console.log "keydown event", event.keyCode
    if event.keyCode in [13, 38, 40]
      switch event.keyCode
        when 13 then @hitEnter event
        when 38 then @hitUp event
        when 40 then @hitDown event
      event.preventDefault()
      return off

    @events.emit "keydown", event

  onkeyup: (event) ->
    @events.emit "keyup", event
    if event.keyCode in [13, 38, 40]
      event.preventDefault()
      return off
    @getOffsetLeft()

  textSpan: -> $("<span>").attr("contenteditable", yes).text("@")

  keydown: (callback) -> @events.on "keydown", callback
  keyup: (callback) ->
    @events.on "keyup", callback

  hitEnter: (event) ->
    if @hasMenu then @selectOption()
    console.log event
  hitUp: (event) ->
    if @hasMenu then @selectLast()
    console.log event
  hitDown: (event) ->
    if @hasMenu then @selectNext()
    console.log event

  replaceHTML: (html) -> @input.html html
  getHTML: -> @input.html()

  getOffsetLeft: ->
    range = document.getSelection().getRangeAt(0)
    return null unless range.collapsed
    node = range.commonAncestorContainer
    text = node.data
    return null unless text?
    start = range.startOffset
    end = range.endOffset

    before = text[...start]
    after = text[start..]
    # console.log "so got:", "####{before}##{after}###"

    suggests = @read before
    if suggests.length > 0

      $(node).after "<span id='cursor'></span>"
      cursor = @elem.find("#cursor")
      node.data = before
      
      # console.log "positioning", "####{before}##{after}###"
      @position = cursor.position(@elem)
      @drawMenu suggests
      @dropMenu()
      @moveMenu() if @piece is ""
      @selectNext()
      
      cursor.remove()
      node.data = text

      newRange = document.createRange()
      newRange.setStart node, start
      newRange.collapse yes
      sel = document.getSelection()
      sel.removeAllRanges()
      sel.addRange newRange

    else
      @foldMenu()

  insertTag: (data) ->
    range = document.getSelection().getRangeAt(0)
    node = range.startContainer
    text = node.textContent
    start = range.startOffset
    # end = range.endOffset
    before = text[...start]
    after = text[start..]
    node.data = before[...-1] 
    newText = $(document.createTextNode("x"))
    $(node).after(newText)
    $(node).after (@makeTag data)
    newText[0].textContent = after + ""

    newRange = document.createRange()
    newRange.setStart newText[0], 0
    newRange.collapse = yes
    sel = document.getSelection()
    sel.removeAllRanges()
    sel.addRange newRange

  hasMenu: no

  dropMenu: ->
    unless @hasMenu
      console.log "drop"
      @hasMenu = yes
      @elem.find(".menu").slideDown()

  foldMenu: ->
    if @hasMenu
      @hasMenu = no
      @elem.find(".menu").slideUp()

  moveMenu: ->
    @elem.find(".menu").css "left", "#{@position.left}px"

  optionHTML: (text) -> "<div class='option'>#{text}</div>"

  drawMenu: (list) ->
    @menu.html list.map(@optionHTML).join("")
    console.log "drawing"

  suggest: (map) ->
    @suggest = map

  read: (before) ->
    keys = Object.keys @suggest
    for key in keys
      key = key[0]
      reg = new RegExp "\\" + key + "[\u4e00-\u9fa5a-zA-Z0-9]{0,8}$"
      # console.log "reg", reg
      match = before.match reg
      if match?
        @piece = match[0][1..]
        pattern = new RegExp @piece.split("").join(".{0,6}")
        # console.log "pattern", pattern
        result = @suggest[key].filter (item) -> item.match pattern
        if result.length > 0
          @currentKey = key
          return result

    @currentKey = ""
    return []

  selectClass: (elem) ->
    @elem.find(".selected").removeClass "selected"
    elem.addClass "selected"

  selectNext: ->
    menu = @elem.find(".menu")
    selected = menu.find(".selected")
    if selected.length > 0
      next = selected.next()
      if next.length > 0
        @selectClass next
        return

    @selectClass menu.children().first()

  selectLast: ->
    menu = @elem.find(".menu")
    selected = menu.find(".selected")
    if selected.length > 0
      last = selected.prev()
      if last.length > 0
        @selectClass last
        return
    
    @selectClass menu.children().last()

  selectOption: (elem) ->
    elem = @elem.find(".selected") unless elem?
    text = elem.text()
    @insertTag key: @currentKey, value: text
    @foldMenu()

  makeTag: (data) ->
    close = "<span class='close'>x</span>"
    $("<span key='#{data.key}'
      class='tag' contenteditable='false'
        >#{data.value}#{close}</span>")

  test: ->
    @elem.find(".input").prepend @makeTag key: "@", value: " value "
    @elem.find(".input").prepend @makeTag key: "@", value: " value 2 "