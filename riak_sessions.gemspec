# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'riak_sessions'
  s.version = '0.2'

  s.authors = ['Igor Guerrero']
  s.date = '2009-11-24'
  s.description = "Riak sessions for Rack based application."
  s.email = ['igor@appush.com']
  s.homepage = 'http://appush.com'
  s.files = ['riak_sessions.gemspec', 'CONTRIBUTORS', 'LICENSE', 'README.md', 'lib/riak_sessions.rb',
    'example/app.rb', 'example/config.ru', 'example/views/index.erb']
  s.summary ='Riak sessions for Rack based applications'

  s.add_dependency 'rack', '>= 1.0'
end
