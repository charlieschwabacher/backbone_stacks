#specs for Router class

describe 'router', ->

  beforeEach ->
    App.applicationView = new App.views.ApplicationView()
    App.router = new App.Router()

    App.Router.prototype.viewClasses = []

  describe 'after initialization', ->
    it 'handles all routes with handlePath', ->
      #rebind route handlers after creating a spy
      Backbone.history.handlers = []
      spyOn App.router, 'handlePath'
      App.router.initialize()

      #check regex
      handler = Backbone.history.handlers[0]
      expect(Backbone.history.handlers.length).toBe 1
      expect(handler.route.toString()).toBe '/^(.*?)$/'

      #check that route gets called
      handler.callback()
      expect(App.router.handlePath).toHaveBeenCalled()

    it 'handles App.applicationView navigate events with updatePath', ->
      #rebind events with after creating a spy
      spyOn App.router, 'updatePath'
      App.router.initialize()

      array = []
      App.applicationView.trigger 'navigate', array
      expect(App.router.updatePath).toHaveBeenCalledWith(array)


  describe 'when registering a PageView class', ->

    describe 'when compiling a regex from a baseUrlFragment string', ->
      it 'matches a single fragment', ->
        fragment = 'fragment'
        result = '/^fragment$/i'
        expect(App.Router.compileRegexForFragment(fragment).toString()).toBe result

      it 'matches a single fragment with a wildcard', ->
        fragment = 'fragment/:wildcard'
        result = '/^fragment\\/([0-9a-z_]+)$/i'
        expect(App.Router.compileRegexForFragment(fragment).toString()).toBe result

      it 'matches multiple fragments', ->
        fragment = 'fragment1/fragment2'
        result = '/^fragment1\\/fragment2$/i'
        expect(App.Router.compileRegexForFragment(fragment).toString()).toBe result

      it 'matches multiple fragments with multiple wildcards', ->
        fragment = 'fragment1/:wildcard1/fragment2/:wildcard2'
        result = '/^fragment1\\/([0-9a-z_]+)\\/fragment2\\/([0-9a-z_]+)$/i'
        expect(App.Router.compileRegexForFragment(fragment).toString()).toBe result

        fragment = 'fragment1/fragment2/:wildcard1/:wildcard2'
        result = '/^fragment1\\/fragment2\\/([0-9a-z_]+)\\/([0-9a-z_]+)$/i'
        expect(App.Router.compileRegexForFragment(fragment).toString()).toBe result


    describe 'when registerPageView is called', ->

      instanceProperties = classProperties = undefined

      beforeEach ->
        instanceProperties = {}

        classProperties =
          baseUrlFragment: 'fragment'

      it 'adds the class to the viewClasses hash', ->
        Subclass = App.views.PageView.extend instanceProperties, classProperties
        expect(_.any(App.Router.prototype.viewClasses, (i) -> i[1] is Subclass)).toBe(true)

      it 'stores a single viewClasses hash on its prototype', ->
        Subclass = App.views.PageView.extend instanceProperties, classProperties
        copy = new App.Router()
        expect(_.any(copy.viewClasses, (i) -> i[1] is Subclass)).toBe(true)

      it 'throws an error when a PageView subclass attempts to register a baseUrlFragment matching a route for an existing PageView', ->
        createSubclass = ->
          Subclass = App.views.PageView.extend instanceProperties, classProperties
        createSubclass()
        expect(createSubclass).toThrow()

  describe 'when handling client url or application view page stack changes', ->

    createClass = (name) ->
      App.views.PageView.extend {}, {baseUrlFragment: name}

    ClassA = ClassB = undefined

    beforeEach ->
      ClassA = createClass 'a'
      ClassB = createClass 'b'

    describe 'handlePath', ->

      it 'sets applicationView page stack from a pathname', ->
        App.router.handlePath 'a/b'
        expect(App.applicationView.pages.length).toBe 2
        expect(App.applicationView.pages[0] instanceof ClassA).toBe true
        expect(App.applicationView.pages[1] instanceof ClassB).toBe true

      it 'handles a base page with an empty string baseUrlFragment', ->
        ClassA = createClass ''
        App.router.handlePath ''
        expect(App.applicationView.pages.length).toBe 1
        expect(App.applicationView.pages[0] instanceof ClassA).toBe true

      it 'handles matched wildcards by passing them as arguments to createFromFragment of the class registered for the preceding fragment', ->

        ClassB = createClass 'b/:wildcard'

        spyOn(ClassB, 'createFromFragment').andCallThrough()
        App.router.handlePath 'a/b/string'
        expect(App.applicationView.pages.length).toBe 2
        expect(App.applicationView.pages[0] instanceof ClassA).toBe true
        expect(App.applicationView.pages[1] instanceof ClassB).toBe true
        expect(ClassB.createFromFragment).toHaveBeenCalledWith App.applicationView.pages, 'string'

      it 'passes entirely numeric wildcards as integers', ->
        ClassB = createClass 'b/:wildcard'
        spyOn(ClassB, 'createFromFragment').andCallThrough()

        App.router.handlePath 'a/b/1'
        expect(ClassB.createFromFragment).toHaveBeenCalledWith App.applicationView.pages, 1

      it 'preserves pages at the bottom of the stack that match the beginning of the pathname', ->
        a = new ClassA()
        App.applicationView.pages = [a]
        App.router.handlePath 'a/b'
        expect(App.applicationView.pages.length).toBe 2
        expect(App.applicationView.pages[0]).toBe a
        expect(App.applicationView.pages[1] instanceof ClassB).toBe true

      it 'calls handleError passing the path when given a pathname with an unrecognized fragment', ->
        spyOn App.router, 'handleError'
        path = 'a/c'
        App.router.handlePath path
        expect(App.router.handleError).toHaveBeenCalledWith path

      it 'calls handleError when a matched PageView class createFromFragment method returns false', ->
        spyOn App.router, 'handleError'
        path = 'a/b'
        ClassB.createFromFragment = -> false
        App.router.handlePath path
        expect(App.router.handleError).toHaveBeenCalledWith path

    describe 'updatePath', ->

      it 'generates a client url path from a passed page stack', ->
        a = new ClassA()
        b = new ClassB()
        spyOn App.router, 'navigate'
        App.router.updatePath [a, b]
        expect(App.router.navigate).toHaveBeenCalledWith 'a/b', trigger: false
