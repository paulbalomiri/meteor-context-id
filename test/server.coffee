
ck= ContextId.combine_keys.bind ContextId
Meteor.methods 
  'get-server-context': ->
    return ContextId.get()
  'get-context-key': (keys)->
    return ContextId.ctx_key(keys)
Meteor.publish 'context-id-test',  ContextId.inPublishContext ->
  ret=[]
  console.error _.keys share.cols
  ret.push share.cols.publishByDirectUserId.find 
    pub_id: this.userId
  ret.push share.cols.publishByUserId.find
    pub_id:ContextId.get('user')
  ret.push share.cols.publishByBrowserSession.find
    pub_id: ContextId.get('browser_session')
  ret.push share.cols.publishByUserBrowserSession.find
    pub_id: ContextId.get('user_browser_session')
  ret.push share.cols.publishByBrowser.find
    pub_id: ContextId.get('browser')
  ret.push share.cols.publishByUserBrowser.find
    pub_id: ContextId.get('user_browser')
  share.cols.publishRegardless.find()