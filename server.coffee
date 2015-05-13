_= lodash
getUserId= (ctx, self)->
  #gets userid in publish functions an  
  return self.userId or Meteor.userId()

_pre_init=
  active_connections:{}
  stopped:false
  
  onConnectionHandler: Meteor.onConnection (conn)->
    _pre_init.active_connections[conn.id]=
      connection:conn
    @onClose ()->
      unless _pre_init.stopped
        delete _pre_init.active_connections[conn.id]
  onLoginHandler: Package['accounts-base']?.Accounts.onLogin (ctx)->
    _.extend _pre_init.active_connections[ctx.connection.id],
      login_ctx: ctx
  stop: ->
    @onConnectionHandler?.stop()
    @onLoginHandler?.stop()
    #the stopped member disables the onStop Listeners
    @stopped= true

# dynamic context
ContextId._DynamicContext = new Meteor.EnvironmentVariable()
ContextId.inPublishContext= (func)->
  return _.wrap func, (orig, args...)->
    ContextId._DynamicContext.withValue this , orig.bind this, args...

class share._ContextId
  constructor: (@config)->
    @collection = new Meteor.Collection(ContextId.config.server_collection)
    if ContextId.config.server_collection
      @_ensure_indices()
    @_init_connection_log()
    ###
    Register own onConnection handler and woth through the possible backlog
    ###
    Meteor.onConnection @_on_connection_cb.bind this
    Package['accounts-base']?Accounts.onLogin @_on_login_cb.bind this

    _pre_init.stop() 
    for conn_id, obj of _pre_init.active_connections
      @_on_connection_cb obj.connection
      if obj.login_ctx?
        @_on_login_cb obj.login_ctx
      delete _pre_init.active_connections[conn_id]
  #make it possible to collect backlogs
    delete _pre_init.onConnectionHandler
  _on_login_cb: (ctx)->
    @collection.update ctx.connection.id
      $set: 
        user_id:ctx.user._id
  _init_connection_log: ->
    #TODO: ensureindex
    if @config.connection_log_collection?
      if _.isString @config.connection_log_collection
        @log_collection= new Meteor.Collection @config.connection_log_collection
      else
        @log_collection = @config.connection_log_collection
      @collection.find().observeChanges
        added:(id, fields)=>
          @log_collection.insert _.extend fields,
            log_time: new Date()
        changed: (id,fields)=>
          prev= @log_collection.findOne {connection_id:id}, 
            sort:
              log_time:-1
          @log_collection.insert _.extend _.omit(prev, '_id'), fields,
            log_time:new Date()
            prev_log_id: prev._id
        removed: (id)=>
          prev = @log_collection.findOne {connection_id:id},
            sort:
              log_time:-1
          @log_collection.insert _.extend _.omit(prev, '_id'),
            log_time:new Date()
            prev_log_id: prev._id
            close_connection:true
  _on_connection_cb: (connection)->
    @collection.insert 
      _id: connection.id
      type:'connection'
      connection_id: connection.id
      connect_time: new Date()
    connection.onClose =>
      @collection.remove connection.id
  _ensure_indices:->
    console.warn('indices not implemented')
  _get_ctx: ->
    ctx= ContextId._DynamicContext.get()
    unless ctx?
      ctx= DDP._CurrentInvocation.get()
    return ctx
  _get_connection: ->
    #console.error "_CurrentInvocation:" , DDP._CurrentInvocation.get()
    ctx= @_get_ctx()
    return ctx?.connection

  _set_user_id: (connection_id,user_id)->
     @collection.update connection_id, 
        $set:
          user_id: user_id
  get: ->
    ctx= @_get_ctx()
    connection_id= ctx?.connection.id
    unless connection_id
      console.error "CurrentInvocation:" , DDP._CurrentInvocation.get()
      console.error StackTrace.printStackTrace().join "\n"
      throw new Meteor.Error('500', "get can only be called from within rpc methods or from publish functions wrapped in ContextId.inPublishContext")
    ret= @collection.findOne connection_id

    #verify the context's user id is in sync with dp, or update otherwhise
    unless ctx.userId==ret.user_id
      console.log("user id changed for connection #{connection_id}")
      @_set_user_id(connection_id, ctx.userId)
      ret.user_id= ctx.userId

    if arguments.length==0
      return _.omit ret, ['_id']
    else 
      return ret?[arguments[0]]
  scope= ContextId.scope

  ###
  scopeKey: (scopes,self)->
    key_parts= []
    for scope in scopes
      connection_id= 
  ###
Meteor.startup ->
 
  Meteor.methods 
    'context-id-update': (data)->
      check data._id, undefined
      if data.user_id
        console.error 'ignoring user_id set by user!'
        delete data.user_id
      ctx= ContextId.get()
      ContextId.collection.update ctx.connection_id, 
        $set: data
      console.error "updated state from: ", ctx, " to: ", ContextId.collection.findOne(ctx.connection_id)
      ###
      setUserId is called for the side effect of reevaluating all subscriptions
      ###
      @setUserId(@userId)
      return ctx._id


