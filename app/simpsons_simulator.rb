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

get '/lisa' do
  "The baritone sax is the best sax"
end

post '/lisa' do
  gift = parse_gift(request.body.read)
  if gift == 'book'
    [200, 'I love it']
  elsif gift == 'saxaphone'
    [200, 'I REALLY love it']
  elsif gift == 'video_game'
    [400, 'I hate it']
  elsif gift == 'skateboard'
    [400, 'I REALLY hate it']
  else
    [400, "None of these were part of this prompt, so I'm impartial :O"]
  end
end
