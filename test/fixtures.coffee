ck= ContextId.combine_keys.bind ContextId
global_id=0

#remove any preexisting entries
for name,col of share.cols
  col.remove({})

for doc_nr in _.range(1,4)
  share.cols.publishRegardless.insert
    id:global_id++
    text:"Doc nr.#{doc_nr} free for all"
  for user_id in [share.users...,null]
    share.cols.publishByUserId.insert
      id:global_id++
      pub_id:ck user_id
      text:"Doc nr.#{doc_nr} for user #{user_id}"
    share.cols.publishByDirectUserId.insert
      id:global_id++
      pub_id:ck user_id
      text:"Doc nr.#{doc_nr} for user #{user_id}"
    
    for browser , sessions of share.browser_sessions
      share.cols.publishByUserBrowser.insert
        id:global_id++
        pub_id: ck user_id,browser
        text: "Doc nr.#{doc_nr} for user #{user_id}, Browser: #{browser}"
      for session in sessions
        share.cols.publishByUserBrowser.insert
        id:global_id++
        pub_id: ck user_id,browser,session
        text: "Doc nr.#{doc_nr} for user #{user_id}, Browser: #{browser}, Session:#{session}"
  for browser, sessions of share.browser_sessions
      share.cols.publishByBrowser.insert
        id:global_id++
        pub_id: ck browser
        text: "Doc nr.#{doc_nr} for any user, Browser: #{browser}"
      for session in sessions
        share.cols.publishByBrowserSession.insert
        id:global_id++
        pub_id: ck browser,session
        text: "Doc nr.#{doc_nr} for any user Browser: #{browser}, Session:#{session}"


#Prepend global id to text
for name,col of share.cols
  col.find({text:{$exists:true}}).forEach (doc)->
    #console.log "updating #{name}.#{doc._id}"
    col.update doc._id,
      $set:
        text: "#{doc.id}: #{doc.text}"
