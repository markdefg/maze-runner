#!/usr/bin/env ruby

require 'net/http'

http = Net::HTTP.new('localhost', '9339')
request = Net::HTTP::Post.new('/')
request['Content-Type'] = 'application/json'

request.body = case ENV['request_type']
when 'equal'
 '{"animals":["bear","fox","goat","parrot"],"fruits":{"apple":{"color":"red","types":248},"cherry":{"color":"black","types":17}}}'
when 'fuzzy match'
 '{"animals":["bear","fox","goat","parrot"],"fruits":{"apple":{"color":"green","types":248},"cherry":{"color":"white","types":17}}}'
when 'subset'
 '{"items":[{"subset":{"animals":["bear","fox","goat","parrot"],"fruits":{"apple":{"color":"red","types":248},"cherry":{"color":"black","types":17}}}}]}'
when 'missing key'
 '{"fruits":{"apple":{"color":"red","types":248},"cherry":{"color":"black","types":17}}}'
when 'extra object in array'
 '{"animals":["bear","fox","goat","parrot","sheep"],"fruits":{"apple":{"color":"red","types":248},"cherry":{"color":"black","types":17}}}'
when 'different object in array'
 '{"animals":["bear","fox","sheep","parrot"],"fruits":{"apple":{"color":"red","types":248},"cherry":{"color":"black","types":17}}}'
when 'missing nested object key'
 '{"animals":["bear","fox","goat","parrot"],"fruits":{"apple":{"color":"red"},"cherry":{"color":"black","types":17}}}'
when 'different object for nested key'
 '{"animals":["bear","fox","goat","parrot"],"fruits":{"apple":{"color":[],"types":248},"cherry":{"color":"black","types":17}}}'
when 'fuzzy mismatch'
 '{"animals":["bear","fox","goat","parrot"],"fruits":{"apple":{"color":"red-orange","types":248},"cherry":{"color":"black","types":17}}}'
when 'ignore'
 '{"animals":["bear","fox","goat","parrot"],"fruits":{"apple":"some nonsense","cherry":{"color":"black","types":17}}}'
when 'different fixnum in object'
 '{"animals":["bear","fox","goat","parrot"],"fruits":{"apple":{"color":"red","types":24},"cherry":{"color":"black","types":17}}}'
when 'session'
 '{"sessions":[{"id":"12345"}]}'
when 'event-match'
 '{"events":[{"session":{"id":"12345"}}]}'
when 'event-no-match'
 '{"events":[{"session":{"id":"54321"}}]}'
else
  exit(1)
end

http.request(request)
