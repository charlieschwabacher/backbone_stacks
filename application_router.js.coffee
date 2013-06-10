#handles routing for the single page app based on a page view stack
#we will not need to create any other backbone routers, or call any functions on this router other than start()
#it listens to events on App.applicationView and updates the path accordingly

App.Router = Backbone.Router.extend {

  #store an array of registered view classes and their matching regexes on the prototype
  #registered classes are stored as 2 length arrays, [regex, Class]
  viewClasses: []

  #constructor
  initialize: ->
    @route '*path', 'handlePath'
    App.applicationView.on 'navigate', _.bind(@updatePath, this)


  #called when the client url changes, updates the App.applicationView pages stack to reflect the changes
  handlePath: (path) ->

    #remove trailing slashes
    path = path.slice(0,path.length-1) while path[path.length-1] is '/'

    #make sure path contains no invalid charachters
    return @handleError path unless path.match /[a-z0-9_\/]*/i

    #keep an updated stack of PageViews based on path, save originalPath
    originalPath = path
    pages = []

    #keep existing views in the stack that already match the path
    #return if we match the entire thing
    for page in App.applicationView.pages
      match = page.urlFragment()
      if path.slice(0, match.length) == match
        pages.push page
        path = path.substring(match.length).replace(/^\//, '')
        return if App.applicationView.resetWithPages pages if path.length is 0
        continue
      break

    #we attempt to match the longest possible path starting with the first fragment.
    #when we find a match, we create an instance of the registered pageView subclass, add it to the end of the stack,
    #remove the matching fragments from the begininning of the unmatched path, and continue.
    #we throw an error if there is any part of the path that cannot be matched to a registered PageView class,
    #and break when we have matched the entire url

    `OUTER: //`
    loop
      fragments = path.split('/')

      #create queries starting w/ the entire path and removing fragments from the end as we look for a match
      `INNER: //`
      for i in [(fragments.length)..0]

        #if i makes it to 0, we have not found a match, so handle the error
        #if pages.length is 0, add the base page
        return @handleError(originalPath) if i is 0 and pages.length isnt 0

        #create query string
        query = fragments.slice(0,i).join('/')

        #iterate over registered classes, testing the routing regex for each to see if we match
        for [regex, PageViewClass] in @viewClasses

          match = query.match regex

          #if we found a match, call createFromFragment to get a PageView instance and add it to the stack
          if match
            #compile arguments to pass to the createFromFragment call
            args = match.slice(1)
            args = _.map args, (arg) -> if isNaN(arg) then arg else parseInt(arg)
            args = [pages].concat args

            #call createFromFragment
            result = PageViewClass.createFromFragment.apply(PageViewClass, args)

            #handle createFromFragment return value
            return @navigate result, trigger: true, replace: true if typeof result is 'string'
            return @handleError(originalPath) if result is false
            pages.push result

            #remove matched portion of the path and continue
            path = path.slice(query.length)

            #remove leading /
            path = path.slice(1) if path[0] is '/'

            `break INNER`

      `break OUTER` unless path.length > 0


    #reset the App.applicationView's page stack with the newly created stack
    App.applicationView.resetWithPages pages


  #triggered when a PageView returns false, or when a url fragment that does not map to a registered PageView class is used
  #can be used to display an error message or the single page app equivalent of a 404 page
  handleError: (path) ->
    @trigger 'error', path


  #triggered by the navigate event on App.applicationView
  #update the client url path based on the page stack
  updatePath: (stack) ->
    path = []
    path.push view.urlFragment() for view in stack
    path = path.join '/'

    @navigate path, trigger: false


  #starts the router, handles the existing url path
  start: ->
    Backbone.history.start pushState: true


}, {


  #class method to register a PageView subclass to handle url fragments
  registerPageView: (PageViewClass) ->
    
    #check the baseUrlFragment of the page class
    query = PageViewClass.baseUrlFragment.replace(/:/g, '')
    for [regex] in @prototype.viewClasses
      if query.match regex
        throw new Error("Two PageView subclasses cannot register matching fragment: '#{PageViewClass.baseUrlFragment}'")

    @prototype.viewClasses.push [@compileRegexForFragment(PageViewClass.baseUrlFragment), PageViewClass]


  #compiles a url fragment matching regex from a url fragment string
  compileRegexForFragment: (fragment) ->
    compiled = _.map(fragment.split('/'), (part) ->
      
      #wildcards begin w/ colon
      if part[0] is ':'
        throw new Error('invalid url fragment: wildcards in url fragment must have names') if part.length <= 1
        "([0-9a-z_]+)"
      
      #otherwise we can just include the part
      else
        part

    ).join('\\/')

    new RegExp("^#{compiled}$", 'i')

}
