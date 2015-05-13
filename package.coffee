Package.describe
  name:"pba:context-id"
  description: "bringme helpers functions in hlp global variable"
Package.on_use (api)->
  api.export 'ContextId'
  
  api.use [
      'alethes:lodash@0.7.1'
      'coffeescript'
      'tracker'
      'ddp'
    ]
  api.use ['accounts-base'], ['client','server'], 
    weak:true
  api.use ['sha', 'base64','peerlibrary:stacktrace'], ['client','server' ]
  

  api.add_files ['hexutil.js','common.coffee'], ['client', 'server']
  api.add_files 'server.coffee', 'server'
  api.add_files ['client.coffee'], 'client'


Package.on_test (api)->
  api.use [
    'alethes:lodash@0.7.1'
    'pba:context-id'
    'mizzao:accounts-testing'
    'tinytest'
    'coffeescript'
    'accounts-password'
    'sha'
    'base64'
  ]
  api.add_files 'test/common.coffee'
  api.add_files 'test/fixtures.coffee', 'server'
  
  api.add_files ['test/client_helpers.coffee','test/client.coffee'], 'client'
  api.add_files 'test/server.coffee', 'server'

  return

