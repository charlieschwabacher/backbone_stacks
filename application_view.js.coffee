#root view for the entire application.  Its element is <body>.
#creates and manages views for permanent layout elements of a store, and handles display of
#different page views by pushing and popping them from stacks.  Handles the display
#of popup views by creating a backdrop and disabling scrolling.

App.views.ApplicationView = Backbone.View.extend
  events:
    'click .backdrop': 'removePopup'
    'click a': 'navigate'

  #constructor
  initialize: ->
    _.bindAll this, 'launchPopup', 'removePopup', 'navigate'

    #set element to document.body
    #if body is not available yet, defer until jQuery.ready
    if document.body then @setElement document.body else $ => @setElement document.body

    @pages = []
    @subviews = {}


  #clear the body, render the views that are consistent across pages, then re-render the top page view
  render: ->
    @$el.empty()

    for name, view of @subviews
      view.$el.appendTo @el
      view.delegateEvents()
      view.render()

    @_renderPage @pages[pages.length - 1]


  #adds a subview to the application view
  #subviews added this way will be appended to the views element and displayed across page
  #does not render the added subview
  #returns the added view
  addSubview: (name, view, prepend = false) ->
    @subviews[name].destroy() if @subviews[name]?
    @subviews[name] = view
    view.$el[if prepend then 'prependTo' else 'appendTo'](@el)
    view


  #adds a page view to the top of the stack, removes the existing page view form the dom
  #and replaces it with the new one.
  #triggers a navigate event
  pushPage: (page) ->

    #remove existing page
    @_removePage @pages[@pages.length - 1] if @pages.length > 0

    #add new page view to page stack and render it
    @pages.push page
    @_renderPage page

    #trigger navigate
    @trigger 'navigate', @pages

    page


  #removes the page on the top of the stack, triggers a navigate event, returns the popped view
  #throws an error if popping a page would leave the page stack empty.
  #accepts an optional expectedPage argument, throws an error if the argument is defined and not equal
  #to the page at the top of the stack
  popPage: (expectedPage) ->
    throw new Error('ApplicationView cannot pop final page') if @pages.length <= 1
    throw new Error('Expected page not found at top of page stack') if expectedPage? and expectedPage isnt @pages[@pages.length - 1]

    #destroy existing page
    popped = @pages.pop().destroy()

    #add newly uncovered page from the existing stack
    page = @pages[@pages.length - 1]
    @_renderPage page

    #trigger navigate event
    @trigger 'navigate', @pages

    #return popped page
    popped


  #removes all page views above page, returns page or null if page isn’t in stack, triggers navigate
  popToPage: (page) ->
    #index of first page to be removed
    index = _.lastIndexOf(@pages, page) + 1

    #throws an error if page isn't found
    throw new Error('cannot popToPage: page not found in stack') if index is 0

    #returns page if page is already on top of the stack, otherwise removes pages above page
    return page if index is @pages.length
    @pages.pop().destroy() for i in [index...@pages.length]

    #add page to dom and render
    @_renderPage page

    #trigger navigate event
    @trigger 'navigate', @pages

    #return page
    page


  #clears the page stack and resets it with pages, triggers navigate
  #returns the page on top of the new stack
  resetWithPages: (pages) ->
    throw new Error('Pages must be defined and have length >= 1') unless pages? and pages.length > 0

    #destroy existing page views
    for page in @pages
      if page in pages
        @_removePage page if page.el.parentNode?
      else
        page.destroy()

    #reset with new page views
    @pages = pages

    #add new top page to dom and render
    page = pages[pages.length - 1]
    @_renderPage page

    #trigger navigate event
    @trigger 'navigate', @pages

    #return new top page
    page


  #method used to append a pageView and call its delegateEvents and render methods
  #triggers an 'open' event on the newly rendered page
  _renderPage: (page) ->
    page.$el.appendTo @el
    page.delegateEvents()
    page.render()

    page.trigger 'open'

    window.scrollTo 0, 0

    this

  #method used to remove a pageView from the dom when it is still part of the page stack
  #triggers a 'close' event on the newly hidden page
  _removePage: (page) ->
    page.remove()

    page.trigger 'close'

    this


  #accepts a view instance and appends it to @el along with a backdrop, disables scrolling.
  #to returns the appended view and saves a reference to it in subviews
  #throws an error if an existing popup has been launched without being removed.
  launchPopup: (view) ->
    throw new Error('ApplicationView cannot launch new popup before existing popup has been removed') if @subviews.popup?

    $('<div class="backdrop"></div>').appendTo(@el)
    @$el.css(overflow: 'hidden')

    view.$el.appendTo @el
    view.delegateEvents()
    view.render()
    @subviews.popup = view

    view


  #removes @subviews.popup and backdrop, re-enables scrolling, returns the removed popup view
  removePopup: ->
    @$('> .backdrop').remove()
    @$el.css overflow: 'auto'

    if @subviews.popup?
      @subviews.popup.destroy()
      removed = @subviews.popup
      delete @subviews.popup

    removed


  #prevents clicked links from causing a page refresh, instead passes their href to App.router
  navigate: (e) ->
    if e.currentTarget.hostname is window.location.hostname
      path = e.currentTarget.pathname
      App.router.navigate path, trigger: true
      return false
    true
