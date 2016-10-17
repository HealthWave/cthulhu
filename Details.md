Starting the app, after loading all files
  Read routes hash
  Create fanout exchange
  Create routing keys between exchanges


Message comes in
  Find key on routes hash matching routing key
  Instantiate handler and run

Sending message
  Set content-type header to application/json if json
  Set content-type header to object/marshal-dump if it is a dump
  
