
EditorWithTags = (options) ->
  @options = options

  @elem = $("<div>").addClass "editor-with-tags"
  @input = $("<div>").addClass("input").attr "contenteditable", yes
  @menu = $("<div>").addClass("menu")
  @elem.append @input, @menu

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
      console.log "the elem to focus", elem
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
      # event.preventDefault()
      # return off

    @events.emit "keydown", event

  onkeyup: (event) ->
    @events.emit "keyup", event
    @getOffsetLeft()

  textSpan: -> $("<span>").attr("contenteditable", yes).text("@")

  keydown: (callback) -> @events.on "keydown", callback
  keyup: (callback) ->
    @events.on "keyup", callback

  hitEnter: (event) -> console.log event
  hitUp: (event) -> console.log event
  hitDown: (event) -> console.log event

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
    console.log "so got:", "####{before}##{after}###"

    suggests = @read before
    if suggests.length > 0

      $(node).after "<span id='cursor'></span>"
      cursor = @elem.find("#cursor")
      node.data = before
      
      console.log "positioning", "####{before}##{after}###"
      @position = cursor.position(@elem)
      @drawMenu suggests
      @dropMenu()
      @moveMenu() if @piece is ""
      
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

  drawMenu: (list) -> @menu.html list.map(@optionHTML).join("")

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