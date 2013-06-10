#specs for PageView class

describe 'page view', ->

  instanceProperties = classProperties = undefined
  App.applicationView = new App.views.ApplicationView()

  beforeEach ->
    classProperties =
      baseUrlFragment: 'fragment'

    App.Router.prototype.viewClasses = []


  describe 'urlFragment', ->
    it 'by default, returns the baseUrlFragment class property', ->
      Class = App.views.PageView.extend {}, classProperties
      instance = new Class()
      expect(instance.urlFragment()).toBe classProperties.baseUrlFragment

  describe 'when calling extend to create a subclass', ->
    it 'returns a subclass', ->
      Class = App.views.PageView.extend {}, classProperties
      expect(Class.constructor is App.views.PageView.constructor).toBe true

    it 'throws an error if a baseUrlFragment class property is not defined or is not a string', ->
      extend = -> App.views.PageView.extend {}, {}
      expect(extend).toThrow()
      extend = -> App.views.PageView.extend {}, {baseUrlFragment: {}}
      expect(extend).toThrow()

    it 'registers the subclass with App.router', ->
      old = App.Router.registerPageView
      spyOn App.Router, 'registerPageView'
      Subclass = App.views.PageView.extend {}, classProperties
      expect(App.Router.registerPageView).toHaveBeenCalledWith(Subclass)
      App.Router.registerPageView = old
