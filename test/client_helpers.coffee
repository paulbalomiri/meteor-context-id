###
  This method subscribes the dataset according to pub_id for each Collection
###

share.test_subscription= (opts, test_func)->   
  opts= _.defaults
    browser_id:ContextId.ctx_key('browser')
    session_id:ContextId.ctx_key('session')
    subscribe:true
  return (test,ready)->
    reset_ctx= false
    unless opts.browser_id == ContextId.ctx_key('browser')
      window.localStorage[ContextId.localStorageKey]= opts.browser_id
      reset_ctx= true
    unless opts.session_id == ContextId.ctx_key('session')
      reset_ctx= true
      window.sessionStorage[ContextId.sessionStorageKey]= opts.session_id
    user_id= Meteor.userId()
    if _.keys(opts).indexOf('user_id')>-1
      user_id= opts.user_id
      reset_ctx= true
    
    cont= ->
      ready_count=1
      ready_func= ->
        ready_count--
        console.error "ready_count:#{ready_count}"
        unless ready_count
          ready()
      if opts.subscribe
        ready_count=2
        subscription= Meteor.subscribe 'context-id-test', 
          onReady: ->
            console.error "subscription ready"
            test_func(test,ready_func)
            subscription.stop()
          onStop: ->
            console.error "subscription stopped"
            ready_func()
      else
        test_func(test,ready_func)
    if reset_ctx
       Meteor.call 'set-user',  user_id , cont 
    else 
      cont()
share.test_content= (opts)->
  #short for collection
  c= share.cols
  return (test, ready)->
    debugger 
    all=  (collection, filter)->
      test.equal collection.find().fetch(), collection.find(filter).fetch() , "Not all documents pass the filter #{JSON.stringify(filter)}"  
    some= (collection, filter={})->
      res= collection.find(filter)
      test.isTrue res.count()>1 , "At least one document should pass the filter #{JSON.stringify(filter)}"
    none= (collection, filter={})->
      test.equal [], collection.find(filter).fetch() , "No document should pass the filter #{JSON.stringify(filter)}"
    rex= (txt)->
      text:
        $regex: ".*#{rex}.*"
    $in= (txt...)->
      $or: txt.map (t)->
        rex t
    nin=(txt...)->
      $and: txt.map (t)->
        text:
          $not: rex(t).text

    some c.publishRegardless 
    if opts.user_id?
      "publishByDirectUserId,publishByUserId".split(',').forEach (col)->
        all c[col] ,
          $and: [
              rex opts.user_id
        
            ]
        none c[col],
          nin rex(opts.user_id)
      if opts.browser_id?
        all c.publishByUserBrowser ,
          $and: [
              rex opts.user_id
              rex opts.browser_id
            ]
        none c.publishByUserBrowser ,
          nin rex(opts.user_id)
        if opts.session_id
          none c.publishByBrowserSession 
          all c.publishByUserBrowserSession ,
              $and: [
                  rex opts.user_id 
                  rex opts.session_id
                  rex opts.browser_id
                ]
          none c.publishByUserBrowserSession,
            nin rex(opts.user_id), rex(rex opts.session_id), rex(opts.browser_id)
          #some c.publishByUserBrowserSession
        else # user_id, browser_id, no session_id 
          none c.publishByBrowserSession
          none c.publishByUserBrowserSession
          none c.publishByBrowserSession
    
          all c.publishByUserBrowser ,
            $and: [
                rex opts.browser_id
              ]
          none c.publishByUserBrowser,
            nin rex(opts.browser_id)
          
          some c.publishByBrowser
          
      else # user_id, no browser_id, maybe  session_id
        #nothing
    else # no user_id, maybe browser_id, maybe session_id
      if opts.browser_id?
        if opts.session_id?
          nothing
        else #browser_id, no user_id, no session_id
      else #no browser_id, no user_id, no session_id
        #if opts.session_id missing but makes no sense

    ready()