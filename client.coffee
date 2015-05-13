_= lodash

class share._ContextId
  constructor: (@config)->
    #constructor is called at startup time
    @sessionStorageKey= @config.sessionStoreKey
    @localStorageKey= @config.localStoreKey
    @_store={}
    # see http://diveintohtml5.info/storage.html
    if window.addEventListener?
      #Windows explorer
      window.addEventListener("storage", @_handle_storage.bind(this), false);
    else 
      #World
      window.attachEvent("onstorage", @_handle_storage.bind(this))
    @_dependencies=
      __all__: new Tracker.Dependency()
    @_comps={}
    @_comps.connection_autorun = Tracker.autorun =>
      # Read the connection id and forward the reactivity
      status = Meteor.status()
      unless @_store.meteor_session_id == Meteor.connection._lastSessionId or ((not @_store.meteor_session_id?) and not status.connected)
        if status.status in ['connecting', 'connected']
          get_session_id = =>
            @_store.meteor_session_id= Meteor.connection._lastSessionId
            console.error "last session id: #{Meteor.connection._lastSessionId}"
            @_invalidate 'meteor_session_id'
            if @_store.__delay_rpc
              delete @_store.__delay_rpc
            @_invalidate '__delay_rpc'
          if Meteor.connection._lastSessionId
            get_session_id()
          else
            @_store.__delay_rpc= true
            @_invalidate('__delay_rpc')
            # This is only set after the status change for some reason
            Meteor.defer get_session_id
        else
          delete @_store.meteor_session_id
          @_invalidate 'meteor_session_id'
    @_comps.native_store_computation = Tracker.autorun =>
      # do a get to create a dependency
      meteor_session_id= @get 'meteor_session_id'
      for store in "localStorage,sessionStorage".split ','
        prev= @_store[store]
        @_store[store]= window[store][@config["#{store}Key"]] ?= Random.id()
        unless prev == @_store[store]
          @_invalidate(store)
    
    #setting the user id
    @_comps.userId= Tracker.autorun =>
      prev = @_store.user_id
      @_store.user_id = Meteor.userId()
      if prev!= @_store.user_id
        @_invalidate 'user_id'

    @_comps.rpc_computation = Tracker.autorun =>
      @_dependencies.__all__.depend()
      status = Meteor.status()
      if status.connected and not @_store.__delay_rpc
        debugger
        console.log 'calling context-id-update RPC with:', @_store
        arg =  _.omit @_store , (val,prop)->
          debugger
          #don't se
          if (prop.substring(0,2)=="__")
            return true
          else if prop== 'user_id'
            return true
          else
            return false
        if _.keys(arg).length
          Meteor.call 'context-id-update', arg
  _invalidate: (name)->
    @_dependencies[name]?.changed()
    @_dependencies.__all__.changed()
  _handle_storage: (event)->
    unless event.oldValue==event.newValue
      switch event.storageArea 
        when 'localStorage' or 'sessionStorage'
          if e.key== @["#{type}Key"]
            @_store[type]=event.newValue
            @_invalidate type
            return
  get:->
    if arguments.length ==1
        @_dependencies[arguments[0]] ?= new Tracker.Dependency()
        @_dependencies[arguments[0]].depend()
        return @_store[arguments[0]]
    else
      @_dependencies.__all__.depend()
      return @_store


