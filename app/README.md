# Simpsons Simulator
This app is a prototype of a new officially licensed Simpsons Simulator API.
It exposes a sophisticated AI model of the fictional Simpsons household from
the long-running television show.  Each character:
  * Gives a greeting
  * Accepts a gift that they like
  * Rejects gifts that they don't like

The API is implemented as a [Ruby](https://ruby-lang.org) application using the [Sinatra](https://sinatrarb.com) web framework.

## Running locally

Prequisites:
  * The version of Ruby specified in the `.ruby-version` file installed and on
    your path
  * The [Bundler](https://bundler.io) gem >= 2 installed and on your path

Starting a local server:

    $ make run
    bundle install
    Using bundler 2.0.2
    Using ruby2_keywords 0.0.2
    Using mustermann 1.1.1
    Using rack 2.2.3
    Using rack-protection 2.0.8.1
    Using tilt 2.0.10
    Using sinatra 2.0.8.1
    Bundle complete! 1 Gemfile dependency, 7 gems now installed.
    Use `bundle info [gemname]` to see where a bundled gem is installed.
    bundle exec ruby app.rb
    [2020-08-02 11:33:05] INFO  WEBrick 1.4.2
    [2020-08-02 11:33:05] INFO  ruby 2.6.3 (2019-04-16) [x86_64-darwin18]
    == Sinatra (v2.0.8.1) has taken the stage on 4567 for development with backup from WEBrick
    [2020-08-02 11:33:05] INFO  WEBrick::HTTPServer#start: pid=65308 port=4567

Test that your local server is working:

    $ curl localhost:4567
    Welcome to the Simpson household

## Running in 'production'

`make run-production` adds an option that will be helpful in getting the application
to run in a production-like environment.

## TODO
Because of the complexity of developing the AI models for each character, only
Homer Simpson has been implemented so far.  Next on the list to be implemented
is Lisa Simpson.
