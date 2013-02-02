#!/usr/bin/env ruby

require 'socket'

module Argos
  class RequestHandler

    INDEX_FILE = File.expand_path(File.join(File.dirname(__FILE__), "../index.html"))

    def initialize(logger = RequestLogger.new)
      @logger = logger
    end

    def handle(socket)
      log("Got a request! How exciting!")
      request = socket.gets
      log("Incoming: #{request}")

      url = parse_path(request)
      if !url.empty?
        if url == "index.html"
          log("Request is for home page, responding immediately.")
          socket.print quick_resp(File.read(INDEX_FILE), 200, "text/html")
        elsif url == "favicon.ico"
          log("Request is for favicon, responding immediately.")
          socket.print quick_resp("Nope", 404)
        else
          valid = Resource.new(url, @logger).fetch(socket)
          socket.print quick_resp("Invalid format.", 404) if !valid
        end
      else
        log("Invalid request, responding immediately.")
        socket.print quick_resp("You failed.", 404)
      end
    end

    private

    def log(msg)
      @logger.log(msg)
    end

    def parse_path(request)
      if request =~ /^GET \/(.*?)\s+HTTP\/\d\.\d\r\n$/i
        return $1[/.+/m] || "index.html"
      end
      ""
    end

    def quick_resp(message, status_code = 200, content_type = "text/plain")
      "HTTP/1.1 #{status_code}\r\n" +
      "Content-Type: #{content_type}\r\n" +
      "Content-Length: #{message.length}\r\n" +
      "\r\n" +
      message
    end

  end
end
