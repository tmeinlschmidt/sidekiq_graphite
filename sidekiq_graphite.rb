#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"

require 'redis-sentinel'
require 'sidekiq'
require 'sidekiq/api'
require 'redis'
require 'redis-namespace'
require 'graphite-api'
require 'graphite-api/core_ext/numeric'

module ConfigFile

  def self.load_yaml(object)
    return case object
    when Hash
      object = object.clone
      object.each do |key, value|
      object[key] = load_yaml(value)
    end
    OpenStruct.new(object)
    when Array
      object = object.clone
      object.map! { |i| load_yaml(i) }
    else
      object
    end
  end

end

module Collector

  class Poll

    def initialize
      settings = ConfigFile.load_yaml(
        YAML.load_file(File.dirname(Pathname.new(__FILE__).realpath)+'/config.yml'))
      sentinels = settings.redis.sentinels.map(&:marshal_dump)
      raise 'Missing sentinels config' if sentinels.empty?

      graphite = settings.graphite
      raise 'Missing graphite config' if graphite.nil?

      params = { graphite: "#{graphite.host}:#{graphite.port}", prefix: [graphite.prefix]}

      _redis = Redis.new(
        master_name: settings.redis.sentinel_master_name,
        sentinels: sentinels)

      if settings.redis.namespace
        @redis = ConnectionPool.new(size: 10) do
          Redis::Namespace.new(settings.redis.namespace, redis: _redis)
        end
      else
        @redis = ConnectionPool.new(size: 10) { _redis }
      end

      Sidekiq.configure_client do |config|
        config.redis = @redis
      end
      @graphite = GraphiteAPI.new( params )
      c = @graphite
      Zscheduler.every(settings.general.poll) do
        begin
          print '.'
          stats = Sidekiq::Stats.new
          workers = Sidekiq::Workers.new
          c.metrics('sidekiq.workers' => workers.size)
          c.metrics('sidekiq.jobs.pending' => stats.enqueued)
          c.metrics('sidekiq.jobs.processed' => stats.processed)
          c.metrics('sidekiq.jobs.failed' => stats.failed || 0)
          c.metrics('sidekiq.workers' => workers.size)
          c.metrics('sidekiq.workers' => workers.size)
          stats.queues.each do |name, jobs|
            c.metrics("sidekiq.queue.#{name}" => jobs)
            klasses = Sidekiq::Queue.new(name).map(&:klass).inject({}){|a,v| a[v] = (a[v]) ? a[v]+=1:1; a}
            klasses.each do |klass, cnt|
              c.metrics("sidekiq.klasses.queue.#{name}.klass.#{klass}" => cnt)
            end
          end
        rescue Redis::TimeoutError
          raise 'Redis server timeout'
        rescue  Redis::CannotConnectError, Redis::ConnectionError
          raise 'Could not connect to redis'
        rescue Exception => e
          raise 'Could not connect to redis'
        end
      end
      Zscheduler.join
    end

  end

  service = Collector::Poll.new

end
