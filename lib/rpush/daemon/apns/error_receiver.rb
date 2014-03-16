module Rpush
  module Daemon
    module Apns
      class ErrorReceiver
        SELECT_TIMEOUT = 0.2
        ERROR_TUPLE_BYTES = 6
        ERROR_TUPLE_FORMAT = 'ccN'
        APN_ERRORS = {
          1 => "Processing error",
          2 => "Missing device token",
          3 => "Missing topic",
          4 => "Missing payload",
          5 => "Missing token size",
          6 => "Missing topic size",
          7 => "Missing payload size",
          8 => "Invalid token",
          255 => "None (unknown error)"
        }

        def initialize(app, connection)
          @app = app
          @connection = connection
        end

        def start
          @thread = Thread.new do
            while true
              receive_error
            end
          end
        end

        def stop
        end

        def dispatched(notification)
        end

        private

        def receive_error
          if @connection.select(SELECT_TIMEOUT)
            error = nil

            if tuple = @connection.read(ERROR_TUPLE_BYTES)
              _, code, notification_id = tuple.unpack(ERROR_TUPLE_FORMAT)

              description = APN_ERRORS[code.to_i] || "Unknown error. Possible Rpush bug?"
              error = Rpush::DeliveryError.new(code, notification_id, description)
            else
              error = Rpush::Apns::DisconnectionError.new
            end

            begin
              log_error("Error received, reconnecting...")
              @connection.reconnect
            ensure
              raise error if error
            end
          end
        end
      end
    end
  end
end
