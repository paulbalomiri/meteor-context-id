_= lodash
share.cols= {}
for col in "publishByDirectUserId,publishByUserId,publishByBrowserSession,publishByUserBrowserSession,publishByBrowser,publishByUserBrowser,publishRegardless".split(',')
  console.log "Creating collection #{col}"
  share.cols[col] = new Meteor.Collection col


_.extend share,
  users: 'userA,userB,userC'.split ','
  browsers: 'browserA,browserB,browserC'.split ','
share.browser_sessions= _.object share.browsers.map (browser)->[browser, "sessionA,sessionB,sessionC".split(',')]





#prepend global id to text
for name,col of share.cols
  col.find().forEach (doc)->
    col.update doc._id, 
      text: "#{doc.id}:" + doc.text

Meteor.methods
  'set-user': (user_id)->
    @setUserId(user_id)


#Tinytest.add 'Read Context variables', (test)->
#  test.isTrue ContextId.get 'localStorage'
#  test.isTrue ContextId.get 'sessionStorage'
#  test.isTrue ContextId.get 'userId'
  