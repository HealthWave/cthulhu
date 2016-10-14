Cthulhu.configure do
  # The organization. Example: 'com.example'
  organization = '__ORGANIZATION__'
  app_name = '__APP_NAME__'
  fqan = "#{organization}.#{app_name}"
  parent_inbox_exchange = fqan
  inbox_exchange = "#{parent_inbox_exchange}.#{inbox}"
end
