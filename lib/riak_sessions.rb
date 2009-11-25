require 'rack/session/abstract/id'
require 'thread'
require 'base64'
require 'jiak'

module Rack

  # The Rack::Session::Riak uses the open source document-oriented web database Riak as a sessions backend,
  # it uses the Jiak ruby client library: http://hg.basho.com/riak/src/tip/client_lib/jiak.rb
  # more info about Riak: http://riak.basho.com/
  #
  # Examples:
  #     use Rack::Session::Riak
  #     will use Riak as a session handler

  module Session
    class RiakPool
      def initialize(server, port, options)
        @riak = JiakClient.new(server, port, '/jiak/', options)
      end

      def [](session_id)
        get(session_id)
      end

      def get(session_id)
        raise if session_id.nil? or session_id.empty?
        session = @riak.fetch('rack_session', session_id)
        data = Marshal.load(Base64.decode64(session['object']['data']))
        return data
      rescue JiakException => e
        return nil
      end

      def store(session_id, data)
        set(session_id, data)
      end

      def set(session_id, data)
        begin
          raise JiakException if session_id.nil?
          session = @riak.fetch('rack_session', session_id)
        rescue JiakException => e
          session = {'bucket'=>'rack_session', 'key'=>session_id, 'links'=>[]}
        end
        session['object'] = {'data'=>Base64.encode64(Marshal.dump(data))}
        @riak.store(session)
        return true
      end

      def delete(session_id)
        @riak.delete('rack_session', session_id)
      end
    end

    class Riak < Abstract::ID
      attr_reader :mutex, :pool
      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge(
        :drop         => false,
        :riak_server  => '127.0.0.1',
        :riak_port    => 8098,
        :riak_options => {'w'=>'3','dw'=>'3'})

      def initialize(app, options={})
        super

        @pool = RiakPool.new(@default_options[:riak_server],
                             @default_options[:riak_port],
                             @default_options[:riak_options])
        @mutex = Mutex.new
      end

      def get_session(env, sid)
        session = @pool[sid] if sid
        @mutex.lock if env['rack.multithread']

        unless sid and session
          env['rack.errors'].puts("Session '#{sid.inspect}' not found, initializing...") if $VERBOSE and not sid.nil?
          session = {}
          sid = generate_sid
          @pool.store sid, session
        end

        return [sid, session]
      ensure
        @mutex.unlock if env['rack.multithread']
      end

      def set_session(env, session_id, new_session, options)
        @mutex.lock if env['rack.multithread']

        if options[:renew] or options[:drop]
          @pool.delete session_id
          return false if options[:drop]
          session_id = generate_sid
          @pool.store session_id, 0
        end

        @pool.store session_id, new_session
        return session_id
      rescue
        warn "#{new_session.inspect} has been lost."
        warn $!.inspect
      ensure
        @mutex.unlock if env['rack.multithread']
      end
    end
  end
end
