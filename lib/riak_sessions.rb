require 'rack/session/abstract/id'
require 'thread'

module Rack

  # The Rack::Session::Riak uses the open source document-oriented web database Riak as a sessions backend,
  # more info about Riak: http://riak.basho.com/
  #
  # Examples:
  #     use Rack::Session::Riak
  #     will use Riak as a session handler

  module Session
    class RiakPool
      def initialize(host, port, options={})
        @host= host
        @port = port
        @path ='/raw/riak_session'
      end

      def [](session_id)
        get(session_id)
      end

      def get(session_id)
        req = Net::HTTP::Get.new([@path, session_id].join('/'))
        res = Net::HTTP.start(@host, @port) { |http| http.request(req) }
        return Marshal.load(res.body)
      rescue Net::HTTPNotFound => e
        return nil
      end

      def store(session_id, data)
        set(session_id, data)
      end

      def set(session_id, data)
        req = Net::HTTP::Put.new([@path, session_id].join('/'))
        req.content_type = 'application/octet-stream'
        req.body = Marshal.dump(data)
        Net::HTTP.start(@host, @port) { |http| http.request(req) }
        return true
      end

      def delete(session_id)
        req = Net::HTTP::Delete.new([@path, session_id].join('/'))
        Net::HTTP.start(@host, @port) { |http| http.request(req) }
      end
    end

    class Riak < Abstract::ID
      attr_reader :mutex, :pool
      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge(
        :drop         => false,
        :riak_server  => '127.0.0.1',
        :riak_port    => 8098
      )

      def initialize(app, options={})
        super

        @pool = RiakPool.new(@default_options[:riak_server],
                             @default_options[:riak_port])
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
