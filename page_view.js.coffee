#superclass for views representing individual 'pages' of our single page app
#
#subclasses must define a baseUrl string and a createFromFragment function as class properties.  These
#are used by App.router to handle client side url routing.  To navigate, the router splits up a url path into
#fragments, and calls createFromFragment() for each to produce a stack of views.  Fragments beginning w/ numbers
#are passed to the createFromFragment call for the preceding fragment (these can be model ids, page numbers, etc.)
#In addition to baseUrl and createFromFragment, PageView subclasses must define a urlFragment() method called on
#instances to return a unique client url fragment (base url, plus an optional numeric identifier).

App.views.PageView = Backbone.View.extend {

  #this can be defined by subclasses to return the client url fragment for the view as a string.
  #if overloaded, it should be “#{@baseUrlFragment}/#{numericIdentifier}”
  urlFragment: -> @constructor.baseUrlFragment

  #set a default destroy function.  this can be overriden to unbind events.
  destroy: ->
    @remove()

}, {

  #this should be defined by subclasses
  baseUrlFragment: ''

  #this class method should be defined by subclasses to create and return an instance of the subclass
  #given a numericIdentifier (usually a model id), and the views below it in the page stack.
  #Subclasses that expect certian pages to be or not to be below them in stack should check here.  If
  #there is a problem with the stack, they can stop stack creation and trigger the Router's
  #invalidPage method by returning false.
  createFromFragment: (numericIdentifer, parents) -> new this()

}

#overload the standard backbone extend function to ensure that baseUrlFragment, createFromFragment,
#and urlFragment have been defined and to register the PageView subclass with App.router
App.views.PageView.extend = (protoProps, classProps) ->
  
  #check for baseUrlFragment class property
  unless classProps? and classProps.baseUrlFragment? and typeof classProps.baseUrlFragment is 'string'
    throw new Error('PageView subclasses must define a baseUrlFragment string as a class property')

  #call default backbone extend function
  PageViewClass = Backbone.View.extend.apply this, arguments

  #register the PageView subclass with App.router
  App.Router.registerPageView PageViewClass

  #return the newly created Class
  PageViewClass