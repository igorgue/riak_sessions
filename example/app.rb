require 'rubygems'
require 'sinatra/base'
require 'rack-flash'

require '../lib/riak_sessions'

class App < Sinatra::Base
  use Rack::Session::Riak

  use Rack::Flash

  get '/' do
    flash[:notice] = "hello!"
    erb :index   
  end
end
