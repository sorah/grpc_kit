# frozen_string_literal: true

module GrpcKit
  class InterceptorRegistry
    def initialize(interceptors)
      @interceptors = interceptors

      validate_interceptors
    end

    def build
      @interceptors.dup
    end

    private

    def validate_interceptors
      unless @interceptors
        raise ArgumentError, 'interceptors must not be nil'
      end

      if @interceptors.empty?
        raise ArgumentError, 'interceptors must not be empty'
      end

      invalid_interceptors = @interceptors.reject do |interceptor|
        interceptor.class.ancestors.include?(GrpcKit::GRPC::Interceptor)
      end

      unless invalid_interceptors.empty?
        raise ArgumentError, "interceptor #{invalid_interceptors} must descend from #{GrpcKit::GRPC::Interceptor}"
      end
    end
  end
end
