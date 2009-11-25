Riak Sessions
=============

Using [Riak][1] to store sessions in Rack based applications.

Overview
--------

Lets say you are already using Riak, this awesome document-oriented Web and you
might think of avoiding using Memcache, Pool and since you already have a 
database, lets store it there right?, this library plugs it into Rack so you
can use it in your Sinatra, Merb, Camping, etc.

Why?
----

Because I kinda like Riak.

Installing
----------

Get Riak: [http://riak.basho.com/][1]
Get the Jiak Ruby client: [http://hg.basho.com/riak/src/tip/client_lib/jiak.rb][2]

Usage
-----

Quick Sinatra app, using flash to test the sessions (included in the examples folder too):

/config.ru:

    require 'app'

    run App

/app.rb:

    require 'rubygems'
    require 'sinatra/base'
    require 'rack-flash'
    require 'rack_sessions'

    class App < Sinatra::Base
      use Rack::Session::Riak

      use Rack::Flash

      get '/' do
        flash[:notice] = "hello!"
        erb :index   
      end
    end

/views/index.erb

    <% if flash.has?(:notice) %>
      <h1>Notice: <%= flash[:notice] %></h1>
    <% end %>

You can also specify options to your Riak server and port and options:

    use Rack::Session::Riak, :riak_server => 'example.com', :riak_port => 8888, :options => {'w'=>'3','dw'=>'3'}

[1]: http://riak.basho.com/
[2]: http://hg.basho.com/riak/src/tip/client_lib/jiak.rb
