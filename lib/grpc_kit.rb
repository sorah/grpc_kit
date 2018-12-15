# frozen_string_literal: true

require 'logger'

require 'grpc_kit/grpc/core'
require 'grpc_kit/grpc/errors'
require 'grpc_kit/grpc/generic_service'
require 'grpc_kit/grpc/interceptor'
require 'grpc_kit/grpc/logger'
require 'grpc_kit/version'
require 'grpc_kit/server'
require 'grpc_kit/client'

module GrpcKit
  class << self
    # @param value [Logger] Any logger
    attr_writer :logger

    # @return [Logger]
    def logger
      @logger ||= Logger.new(STDOUT, level: ENV['GRPC_KIT_LOGLEVEL'] || :info)
    end

    # @param level [String] :debug, :info, :warn, :error, :fatal or :unknown
    # @return [void]
    def loglevel=(level)
      logger.level = level
    end

    def base_client_class
      @base_client_class || GrpcKit::Client
    end

    def base_client_class=(value)
      unless value.ancestors.include?(GrpcKit::Client)
        raise 'base_client_class must inherit GrpcKit::Client'
      end

      @base_client_class = value
    end
  end
end
