
EditorWithTags = (options) ->

  @elem = $("<div>").addClass "editor-with-tags"
  @input = $("<div>").addClass("input")
  @menu = $("<div>").addClass("menu")
  @elem.append @input, @menu

  self = @

  @input.focus (@focus.bind self)
  @input.blur (@blur.bind self)
  @input.keydown (@onkeydown.bind self)
  @input.keyup (@onkeyup.bind self)

  @events = new EventEmitter

  return

EditorWithTags:: =
  contructor: EditorWithTags

  text: (value) ->
    @elem.find(".input").text value

  focus: ->
    console.log "focus"
    @elem.addClass "focus"

  blur: ->
    @elem.removeClass "focus"

  onkeydown: (event) ->
    console.log event.keyCode
    if event.keyCode in [13, 38, 40]
      switch event.keyCode
        when 13 then @hitEnter event
        when 38 then @hitUp event
        when 40 then @hitDown event
      event.preventDefault()
      return no

    @events.emit "keydown", event

  keydown: (callback) -> @events.on "keydown", callback
  keyup: (callback) -> @events.on "keyup", callback

  onkeyup: (event) -> @events.emit "keyup", event

  optionHTML: (text) -> "<div class='option'>#{text}</div>"

  renderMenu: (list) -> @menu.html list.map(@optionHTML).join("")

  hitEnter: (event) -> console.log event
  hitUp: (event) -> console.log event
  hitDown: (event) -> console.log event

  replaceHTML: (html) -> @input.html html
  getHTML: -> @input.html()