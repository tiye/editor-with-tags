
class EditorWithTags
  constructor: (options) ->
    @options = options

    @elem = $("<div>").addClass "editor-with-tags"
    @input = $("<div>").addClass("input").attr "contenteditable", yes
    @menu = $("<div>").addClass("menu")
    @elem.append @input, @menu

    @elem.find(".input").append($(document.createTextNode("")))

    @setupEvents()

  text: (value) =>
    # @elem.find(".input").text value

  delay: (t, f) => setTimeout (=> f()), t

  position:
    left: 0

  editable: (elem) =>
    elem.attr "contenteditable", yes

  setupEvents: =>

    @events = new EventEmitter

    @elem.on "focus", ".input", @focus
    @elem.on "blur", ".input", @blur
    @elem.on "keydown", ".input", @onkeydown
    @elem.on "keyup", ".input", @onkeyup
    @elem.on "click", @clickOnComponent
    @elem.on "click", ".option", @selectClicked
    @elem.on "click", ".tag", @clickOnTag
    $(document).on "click", @loseFocus
    $(document).on "blur", @loseFocus

  focus: =>
    console.log "focus"
    @elem.addClass "focus"
    @delay 0, =>
      # let it focus first, and bind @ here
      @getOffsetLeft()

  blur: =>
    @elem.removeClass "focus"

  clickOnComponent: (event) =>
    event.stopPropagation()
    off

  loseFocus: (event) =>
    @foldMenu()

  onkeydown: (event) =>
    # console.log "keydown event", event.keyCode
    if event.keyCode in [13, 38, 40]
      switch event.keyCode
        when 13 then @hitEnter event
        when 38 then @hitUp event
        when 40 then @hitDown event
      event.preventDefault()
      return off

    @events.emit "keydown", event

  onkeyup: (event) =>
    @events.emit "keyup", event
    if event.keyCode in [13, 38, 40]
      event.preventDefault()
      return off
    @getOffsetLeft()

  textSpan: => $("<span>").attr("contenteditable", yes).text("@")

  keydown: (callback) => @events.on "keydown", callback
  keyup: (callback) =>
    @events.on "keyup", callback

  hitEnter: (event) =>
    if @hasMenu then @selectOption()
    console.log event
  hitUp: (event) =>
    if @hasMenu then @selectLast()
    console.log event
  hitDown: (event) =>
    if @hasMenu then @selectNext()
    console.log event

  replaceHTML: (html) => @input.html html
  getHTML: => @input.html()

  # this means we are seeing if we need to drop the menu
  getOffsetLeft: =>
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
      
      # console.log "positioning", "####{before}##{after}###"
      @position = cursor.position(@elem)
      @drawMenu suggests
      @dropMenu()
      @moveMenu() if @piece is ""
      @selectNext()
      
      cursor.remove()
      node.data = text

      @caretGoto node, start

    else
      @foldMenu()

  insertTag: (data) =>
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
    $(node).next().after document.createTextNode(" ")
    newText[0].textContent = after + ""

    @caretGoto newText[0], 0

  hasMenu: no

  dropMenu: =>
    unless @hasMenu
      console.log "drop"
      @hasMenu = yes
      @elem.find(".menu").slideDown()

  foldMenu: =>
    if @hasMenu
      @hasMenu = no
      @elem.find(".menu").slideUp()

  moveMenu: =>
    @elem.find(".menu").css "left", "#{@position.left}px"

  optionHTML: (text) -> "<div class='option'>#{text}</div>"

  drawMenu: (list) =>
    @menu.html list.map(@optionHTML).join("")
    console.log "drawing"

  loadSuggest: (map) =>
    @suggest = map

  read: (before) =>
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

  selectClass: (elem) =>
    @elem.find(".selected").removeClass "selected"
    elem.addClass "selected"

  selectNext: =>
    menu = @elem.find(".menu")
    selected = menu.find(".selected")
    if selected.length > 0
      next = selected.next()
      if next.length > 0
        @selectClass next
        return

    @selectClass menu.children().first()

  selectLast: =>
    menu = @elem.find(".menu")
    selected = menu.find(".selected")
    if selected.length > 0
      last = selected.prev()
      if last.length > 0
        @selectClass last
        return
    
    @selectClass menu.children().last()

  selectOption: (elem) =>
    elem = @elem.find(".selected") unless elem?
    text = elem.text()
    @insertTag key: @currentKey, value: text
    @foldMenu()

  selectClicked: (event) =>
    @selectOption ($ event.target)

  makeTag: (data) ->
    close = "<span class='close'>x</span>"
    $("<a key='#{data.key}' class='tag' contenteditable='false'>#{data.value} #{}</a>")

  clickOnTag: (event) =>
    currentTag = $ event.target
    text = currentTag.nextSibling
    if not text?
      text = document.createTextNode("")
      currentTag.after text
    @caretGoto text, 0
    event.stopPropagation()
    off

  caretGoto: (elem, start=0) =>
    if window.getSelection?
      range = document.createRange()
      range.setStart elem, start
      range.collapse yes
      selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange range

  test: ->
    @elem.find(".input").prepend @makeTag key: "@", value: " value "
    @elem.find(".input").prepend @makeTag key: "@", value: " value 2 "
