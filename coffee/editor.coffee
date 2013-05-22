
class EditorWithTags
  constructor: (options) ->
    @options = options

    @elem = $("<div>").addClass "editor-with-tags"
    @elem.append $("<div>").addClass("placeholder")
    @elem.find(".placeholder").append $("<span>"), $("<div>").addClass("icon")
    @elem.find(".icon").append $("<img>")
    @input = $("<div>").addClass("input").attr "contenteditable", yes
    @menu = $("<div>").addClass("menu")
    @elem.append @input, @menu

    @elem.find(".input").append($(document.createTextNode("")))

    @setupEvents()

    @piece = ""
    @range = undefined
    @placeholderText = ""

  text: (text) =>
    if text?
      @elem.find(".input").text text
      @
    else
      @elem.find(".input").text()

  takeValue: =>
    tags = @elem.find("a")
    tags.remove()
    text = @elem.find(".input").text().replace /\s+/g, " "

    ret =
      text: text
      tags: {}

    for index in [0...tags.length]
      elem = $ tags[index]
      key = elem.attr "key"
      value = elem.text().trim()
      ret.tags[key] = value

    @elem.find(".input").html("")

    ret

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
    console.log @hasMenu, "keydown event", event.keyCode
    if @hasMenu
      if event.keyCode in [13, 38, 40]
        switch event.keyCode
          when 13 then @hitEnter event
          when 38 then @hitUp event
          when 40 then @hitDown event
        event.preventDefault()
        off
    else
      @events.emit "keydown", event

  onkeyup: (event) =>
    @events.emit "keyup", event
    if event.keyCode in [13, 38, 40]
      event.preventDefault()
      return off
    @getOffsetLeft()
    @maintainPlaceholder()

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
    console.log "at getOffsetLeft", range.startOffset
    return null unless range.collapsed
    if not range.collapsed
      @foldMenu()
      return null
    node = range.commonAncestorContainer
    text = node.data
    if not text?
      @foldMenu()
      return null
    start = range.startOffset
    end = range.endOffset

    before = text[...start]
    after = text[start..]
    console.log "so got:", "####{before}##{after}###"

    suggests = @read before
    if suggests.length > 0
      @range = range
      range.start = range.startOffset

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
    range = @range
    node = range.startContainer
    text = node.textContent
    start = range.start
    # end = range.endOffset
    before = text[...start]
    after = text[start..]
    console.log "piece", @piece
    node.data = before[...-(@piece.length + 1)] 
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
      @elem.find(".menu").show()

  foldMenu: =>
    if @hasMenu
      @hasMenu = no
      @elem.find(".menu").hide()

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
    event.stopPropagation()
    console.log "event", event
    @selectOption ($ event.target)
    off

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

  caretGoto: (elem, start) =>
    if window.getSelection?
      range = document.createRange()
      if start?
        range.setStart elem, start
        range.collapse yes
      else
        range.collapse false
      selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange range

  placeholder: (text) ->
    @placeholderText = text
    @maintainPlaceholder()

  maintainPlaceholder: ->
    console.log "maintain", @elem.find(".input").text().length
    if @elem.find(".input").text().length > 0
      @elem.find(".placeholder span").text ""
    else
      @elem.find(".placeholder span").text @placeholderText

  setIcon: (url) ->
    @elem.find(".icon img").attr "src", url

  test: ->
    @elem.find(".input").prepend @makeTag key: "@", value: " value "
    @elem.find(".input").prepend @makeTag key: "@", value: " value 2 "
