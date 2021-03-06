#!/usr/bin/env ruby

require 'socket'

module Argos
  class Server

    def initialize(address, port)
      @address = address
      @port = port
      @keep_alive = true
    end

    def run
      puts "Starting Argos on #{@address}:#{@port}"
      webserver = TCPServer.new(@address, @port)
      while @keep_alive do
        accept_connection(webserver.accept) do |socket|
          begin
            RequestHandler.new.handle(socket)
            socket.flush
          rescue StandardError => e
            puts "There was an error in handling the request: #{e.inspect}"
            puts "#{e.backtrace.join("\n")}"
          ensure
            socket.close
          end
        end
      end
      puts "Server was shut down."
    end

    def shutdown
      puts "Starting server shutdown sequence..."
      @keep_alive = false
    end

    private

    def accept_connection(socket)
      Thread.start(socket)
    end

  end
end
