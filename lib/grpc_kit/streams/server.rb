# frozen_string_literal: true

require 'grpc_kit/status_codes'

module GrpcKit
  module Streams
    class Server
      # @params stream [GrpcKit::Session::Stream]
      # @params config [GrpcKit::MethodConfig]
      def initialize(stream:, config:)
        @stream = stream
        @config = config
        @sent_first_msg = false
      end

      def send_msg(data, protobuf, last: false, limit_size: nil)
        if last
          @stream.send_trailer # TODO: pass trailer metadata
        end

        buf =
          begin
            @config.protobuf.encode(data)
          rescue ArgumentError => e
            raise GrpcKit::Errors::Internal, "Error while encoding in server: #{e}"
          end

        if limit_size && buf.bytesize > limit_size
          raise GrpcKit::Errors::ResourceExhausted, "Sending message is too large: send=#{req.bytesize}, max=#{limit_size}"
        end

        @stream.write_data(buf, last: last)
        return if @sent_first_msg

        @stream.submit_response
        @sent_first_msg = true
      end

      def recv_msg(protobuf, last: false, limit_size: nil)
        data = @stream.read_data(last: last)

        return nil unless data

        compressed, size, buf = *data

        unless size == buf.size
          raise "inconsistent data: #{buf}"
        end

        if limit_size && size > limit_size
          raise GrpcKit::Errors::ResourceExhausted, "Receving message is too large: recevied=#{size}, max=#{limit_size}"
        end

        if compressed
          raise 'compress option is unsupported'
        end

        raise StopIteration if buf.nil?

        begin
          @config.protobuf.decode(buf)
        rescue ArgumentError => e
          raise GrpcKit::Errors::Internal, "Error while decoding in Server: #{e}"
        end
      end

      def each
        loop { yield(recv) }
      end

      def send_trailer
        @stream.send_trailer # TODO: pass trailer metadata
        @stream.end_write
      end

      def send_status(status: GrpcKit::StatusCodes::INTERNAL, msg: nil, metadata: {})
        @stream.send_trailer(status: status, msg: msg, metadata: metadata)
        return if @sent_first_msg

        @stream.submit_response(piggyback_trailer: true)
        @sent_first_msg = true
      end
    end
  end
end
