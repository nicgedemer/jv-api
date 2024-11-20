require 'sinatra'
require 'json'

def parse_gift(raw)
  parsed = JSON.parse(raw)
  parsed['gift']
end

get '/' do
  "Welcome to the Simpson household"
end

get '/homer' do
  "I hope you brought donuts"
end

post '/homer' do
  gift = parse_gift(request.body.read)
  if gift == 'donut'
    [200, 'Woohoo']
  else
    [400, "D'oh"]
  end
end

###################################
# FIXME: Implement Lisa endpoints #
###################################
