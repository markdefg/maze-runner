# @!group Proxy steps

# Starts an HTTP proxy server.
#
Then('I start an http proxy') do
  Proxy.instance.start :Http
end

# Starts an authenticated HTTP proxy server.
#
Then('I start an authenticated http proxy') do
  Proxy.instance.start :Http, true
end

# Starts an HTTPS proxy server.
#
Then('I start an https proxy') do
  Proxy.instance.start :Https
end

# Starts an authenticated HTTPS proxy server.
#
Then('I start an authenticated https proxy') do
  Proxy.instance.start :Https, true
end

# Test the proxy server handled a request for a host.
#
# @step_input host [String] Destination host to check
Then('the proxy handles a request for {string}') do |host|
  Test::Unit::Assertions.assert_true(Proxy.instance.handled_host?(host),
                                     "The proxy did not handle a request for #{host}")
end

# @!endgroup
