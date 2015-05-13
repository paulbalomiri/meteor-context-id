_= lodash

Tinytest.addAsync 'get-server-context returns something' ,(test, ready)->
  Meteor.call 'get-server-context' , (error,ret)->
    test.isTrue ret , 'No Server context available'
    test.equal ret.localStorage, window.localStorage['client-id'], 'localStorage mismatch'
    test.equal ret.sessionStorage, window.sessionStorage['client-id'], 'sessionStorage mismatch'
    test.equal Meteor.connection._lastSessionId, ret.meteor_session_id, 'Meteor.connection._lastSessionId mismatch'
    ready()


_.each ContextId.scope , (scope, key)->
  Tinytest.addAsync "test key creation for context #{key}=#{scope.join '->'}", (test, ready)->
    scope= ContextId.scope.browser_session 
    Meteor.call 'get-context-key' ,scope, (error,ret)->
      test.equal ret, ContextId.ctx_key scope, " scope #{scope.join ','}store is not the same!"
      ready()

#delay until startup such that ContextId._impl is available
Meteor.startup ->
  opts=
    user_id:'userA'
    browser_id: 'BrowserA'
    session_id: 'SessionA'

  Tinytest.addAsync "test" , share.test_subscription opts , share.test_content opts  

Meteor.call 'set-user', 'userA'

