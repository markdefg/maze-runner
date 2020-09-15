require_relative './lib/features/support/server'
require_relative './lib/features/support/proxy'

Server.start_server
# Set to :Http or :Https depending on desired protocol
# Second parameter is whether auth is enabled on proxy
# Default auth is user:password
Proxy.instance.start :Http, true

gets

at_exit do
  Server.stop_server
  Proxy.instance.stop
end