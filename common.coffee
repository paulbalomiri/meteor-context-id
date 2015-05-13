store= share.store



ContextId = 
  config:
    connection_log_collection: 'connection_log'
    sessionStorageKey:'client-id'
    localStorageKey: 'client-id'

    #Servercollection where to store data. This is the argument to Meteor.Collection, so null means in memory
    server_collection:null
    # Whether to delete connection data when it has expired
    # connection data expires on connection stop 
    server_delete_on_expire:true
  scope:
    user: ['userId']
    user_browser: ['userId', 'localStorage' ]
    user_session: ['userId', 'sessionStorage']
    browser: ['localStorage']
    browser_session: ['localStorage','sessionStorage']
    session: ['sessionStorage']
    default: ['userId', 'sessionStorage']

  fromHex: parseHexString
  toHex: createHexString
  combine_keys: (vals...)->
    if vals.length==1
      #single argument so it's string or list in arguments[0]
      vals= vals[0]
    if _.isArray(vals) and vals.length
      if vals.length==1
        return "#{vals[0]}"
      arr= @fromHex SHA256 vals.join "," 
      return Base64.encode arr
    else
      return "#{vals}"
  ctx_key: (keys)->
    keys?= ContextId.scope.default
    if _.isString keys
      unless @scope[keys]
        throw new Meteor.Error(300,"#{keys} not a valid scope name. defined scope names: #{_.keys(@scope).join ","}")
      keys= @scope[keys]
    if keys.length == 1
      ret= @get keys[0]
      unless ret?
        debugger
        throw new Meteor.Error(300, "key '#{ keys[0] }' is not available" )
      return ret
    vals= keys.map (key)=>
      return @get(key)
    unless _.all vals
      missing_keys= _.compact vals.map (val,idx)->
        if val
          return null
        else return keys[idx]
      throw new Meteor.Error(300, "keys: #{ missing_keys.join "," } are not available" )
    @combine_keys(vals)

Meteor.startup ->
  console.error "executing startup code"
  #only initialize at startup to take into account the config
  ContextId._impl= new share._ContextId(ContextId.config)
  methods_from_default= [
    'get'
    ]
  for method_name in methods_from_default
    ContextId[method_name]= ContextId._impl[method_name].bind ContextId._impl
  ContextId.collection= ContextId._impl.collection