#specs for ApplicationView class

describe 'application view', ->

  applicationView = undefined
  beforeEach ->
    App.applicationView = applicationView = new App.views.ApplicationView()
    App.router = new App.Router()

  describe 'after initialization', ->

    it 'has a pages array', ->
      expect(applicationView.pages).toBeDefined()
      expect(applicationView.pages.length).toBeDefined()

    it 'has a subviews object', ->
      expect(applicationView.subviews).toBeDefined()

    it 'has set its element to document.body', ->
      expect(applicationView.el).toBe document.body


  describe 'when manipulating the page stack', ->

    describe 'pushPage', ->

      firstPage = secondPage = undefined

      beforeEach ->
        firstPage = new App.views.PageView()
        secondPage = new App.views.PageView()
        applicationView.pages = [firstPage]

      it 'adds the page to the end of the page stack', ->
        applicationView.pushPage secondPage
        expect(applicationView.pages[1]).toBe secondPage

      it 'appends the page to the dom', ->
        applicationView.pushPage secondPage
        expect(secondPage.el.parentNode).toBe applicationView.el

      it 'removes the view that was previously at the top of the stack from the dom', ->
        firstPage.$el.appendTo applicationView.el
        applicationView.pushPage secondPage
        expect(firstPage.el.parentNode).not.toBe applicationView.el

      it 'triggers a navigate event passing the page stack', ->
        listener = jasmine.createSpy 'navigate'
        applicationView.on 'navigate', listener
        applicationView.pushPage secondPage
        expect(listener).toHaveBeenCalledWith applicationView.pages

      it 'triggers an open event on the added page', ->
        listener = jasmine.createSpy 'open'
        secondPage.on 'open', listener
        applicationView.pushPage secondPage
        expect(listener).toHaveBeenCalled()

      it 'triggers a close event on the covered page', ->
        listener = jasmine.createSpy 'close'
        firstPage.on 'close', listener
        applicationView.pushPage secondPage
        expect(listener).toHaveBeenCalled()

      it 'returns the newly pushed page', ->
        returnValue = applicationView.pushPage secondPage
        expect(returnValue).toBe secondPage

    describe 'popPage', ->

      firstPage = secondPage = undefined

      beforeEach ->
        firstPage = new App.views.PageView()
        secondPage = new App.views.PageView()
        applicationView.pages = [firstPage, secondPage]

      it 'throws an error if the page stack is empty', ->
        applicationView.pages = []
        expect(applicationView.popPage).toThrow()

      it 'throws an error if the page stack has only one page', ->
        applicationView.pages = [firstPage]
        expect(applicationView.popPage).toThrow()

      it 'throws an error if expected page is passed and is not at the top of the stack', ->
        expect(-> applicationView.popPage(firstPage)).toThrow()

      it 'removes the page at the top of the page stack from the dom', ->
        secondPage.$el.appendTo applicationView.el
        applicationView.popPage()
        expect(secondPage.el.parentNode).not.toBe applicationView.el

      it 'appends the page below it to the dom', ->
        applicationView.popPage()
        expect(firstPage.el.parentNode).toBe applicationView.el

      it 'triggers an open event on the uncovered page', ->
        listener = jasmine.createSpy 'open'
        firstPage.on 'open', listener
        applicationView.popPage()
        expect(listener).toHaveBeenCalled()

      it 'triggers a navigate event passing the page stack', ->
        listener = jasmine.createSpy 'navigate'
        applicationView.on 'navigate', listener
        applicationView.popPage()
        expect(listener).toHaveBeenCalledWith applicationView.pages

      it 'returns the popped page', ->
        returnValue = applicationView.popPage()
        expect(returnValue).toBe secondPage

    describe 'popToPage', ->

      firstPage = secondPage = thirdPage = undefined

      beforeEach ->
        firstPage = new App.views.PageView()
        secondPage = new App.views.PageView()
        thirdPage = new App.views.PageView()
        applicationView.pages = [firstPage, secondPage, thirdPage]

      it 'throws an error if the page is not in the page stack', ->
        applicationView.pages = [firstPage, secondPage]
        expect(-> applicationView.popToPage(thirdPage)).toThrow()

      it 'removes pages above the page from the page stack', ->
        applicationView.popToPage firstPage
        expect(applicationView.pages.length).toBe 1
        expect(applicationView.pages).not.toContain secondPage
        expect(applicationView.pages).not.toContain thirdPage

      it 'appends the page to the dom', ->
        applicationView.popToPage firstPage
        expect(firstPage.el.parentNode).toBe applicationView.el

      it 'triggers an open event on the page', ->
        listener = jasmine.createSpy 'open'
        firstPage.on 'open', listener
        applicationView.popToPage(firstPage)
        expect(listener).toHaveBeenCalled()

      it 'triggers a navigate event passing the page stack', ->
        listener = jasmine.createSpy 'navigate'
        applicationView.on 'navigate', listener
        applicationView.popPage()
        expect(listener).toHaveBeenCalledWith applicationView.pages

      it 'returns the newly uncovered page', ->
        returnValue = applicationView.popToPage firstPage
        expect(returnValue).toBe firstPage

    describe 'resetWithPages', ->

      firstPage = secondPage = thirdPage = fourthPage = undefined

      beforeEach ->
        firstPage = new App.views.PageView()
        secondPage = new App.views.PageView()
        thirdPage = new App.views.PageView()
        fourthPage = new App.views.PageView()
        applicationView.pages = [firstPage, secondPage]

      it 'throws an error if pages is undefined or is not an array with length > 0', ->
        expect(-> applicationView.resetWithPages null).toThrow()
        expect(-> applicationView.resetWithPages []).toThrow()

      it 'removes existing pages from the page stack', ->
        pages = [thirdPage, fourthPage]
        applicationView.resetWithPages pages
        expect(applicationView.pages).toBe pages
        expect(applicationView.pages).not.toContain firstPage
        expect(applicationView.pages).not.toContain secondPage

      it 'removes the old top page from the dom', ->
        secondPage.$el.appendTo applicationView.el
        applicationView.resetWithPages [thirdPage, fourthPage]
        expect(secondPage.el.parentNode).not.toBe applicationView.el

      it 'appends the new top page to the dom', ->
        applicationView.resetWithPages [thirdPage, fourthPage]
        expect(fourthPage.el.parentNode).toBe applicationView.el

      it 'triggers an open event on the top page', ->
        listener = jasmine.createSpy 'open'
        fourthPage.on 'open', listener
        applicationView.resetWithPages [thirdPage, fourthPage]
        expect(listener).toHaveBeenCalled()

      it 'triggers a navigate event passing the page stack', ->
        listener = jasmine.createSpy 'navigate'
        applicationView.on 'navigate', listener
        applicationView.popPage()
        expect(listener).toHaveBeenCalledWith applicationView.pages

      it 'returns the page at the top of the new stack', ->
        returnValue = applicationView.resetWithPages [thirdPage, fourthPage]
        expect(returnValue).toBe fourthPage


  describe 'when handling popups', ->

    popup = secondPopup = undefined

    beforeEach ->
      PopupView = Backbone.View.extend destroy: -> @remove()
      popup = new PopupView()
      secondPopup = new PopupView()

    describe 'launchPopup', ->

      it 'throws an error if there is an existing popup', ->
        applicationView.subviews.popup = popup
        expect(-> applicationView.launchPopup secondPopup).toThrow()

      it 'appends a backdrop to the views element', ->
        applicationView.launchPopup popup
        expect(applicationView.$('div.backdrop').length).toBe 1

      it 'sets the overflow css property to hidden on the views element', ->
        applicationView.launchPopup popup
        expect(applicationView.$el.css('overflow')).toBe 'hidden'

      it 'appends view to the dom', ->
        applicationView.launchPopup popup
        expect(popup.el.parentNode).toBe applicationView.el

      it 'returns the view', ->
        returnValue = applicationView.launchPopup popup
        expect(returnValue).toBe popup

    describe 'removePopup', ->

      beforeEach ->
        applicationView.launchPopup popup

      it 'removes the backdrop element', ->
        applicationView.removePopup()
        expect(applicationView.$('div.backdrop').length).toBe 0

      it 'removes an existing popup from the dom', ->
        applicationView.removePopup popup
        expect(popup.el.parentNode).not.toBe applicationView.el

      it 'restores the overflow css property to auto on the views element', ->
        applicationView.removePopup popup
        expect(applicationView.$el.css('overflow')).toBe 'auto'

      it 'returns the removed popup view', ->
        returnValue = applicationView.removePopup()
        expect(returnValue).toBe popup

  describe 'when responding to dom events', ->

    describe 'when a link is clicked', ->

      link = undefined

      beforeEach ->
        link = $('<a></a>').appendTo applicationView.el
        applicationView.delegateEvents()

      afterEach ->
        link.remove()

      it 'calls navigate', ->
        spyOn applicationView, 'navigate'
        applicationView.delegateEvents()
        link.trigger 'click'
        expect(applicationView.navigate).toHaveBeenCalled()

      it 'returns true if link hostname is different from window.location', ->
        e = currentTarget:
          hostname: 'doesnotmatch'
        returnValue = applicationView.navigate(e)
        expect(returnValue).toBe true

      it 'returns false if link hostname matches window.location', ->
        e = currentTarget:
          hostname: window.location.hostname
          pathname: window.location.pathname
        returnValue = applicationView.navigate(e)
        expect(returnValue).toBe false

      it 'calls App.router.navigate passing the link pathname if link hostname matches window.location', ->
        spyOn App.router, 'navigate'
        e = currentTarget:
          hostname: window.location.hostname
          pathname: 'pathname'
        applicationView.navigate(e)
        expect(App.router.navigate).toHaveBeenCalledWith 'pathname', trigger: true

    describe 'when popup backdrop is clicked', ->

      it 'calls removePopup', ->
        spyOn applicationView, 'removePopup'
        applicationView.delegateEvents()
        popup = new Backbone.View()
        applicationView.launchPopup(popup)
        applicationView.$('div.backdrop').trigger 'click'
        expect(applicationView.removePopup).toHaveBeenCalled()