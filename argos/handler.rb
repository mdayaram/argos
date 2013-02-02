#!/usr/bin/env ruby

require 'socket'
require 'httpclient'

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
        if url == "index.html" || url == "styles/main.css" || url == "styles/github.css"
          log("Request is for home page, responding immediately.")
          socket.print home_page(url)
        elsif url == "favicon.ico"
          log("Request is for favicon, responding immediately.")
          socket.print quick_resp("Nope", 404)
        else
          valid = Resource.new(url, @logger).fetch(socket)
          socket.print redirect_home if !valid
        end
      else
        log("Invalid request, responding immediately.")
        socket.print redirect_home
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

    def home_page(uri)
      uri = "p/argos" if uri == "index.html"
      resp = HTTPClient.new.get("http://noj.cc/#{uri}")
      quick_resp(resp.content, 200, resp.headers['Content-Type'])
    end

    def redirect_home
      log("Redirecting to home page.")
      message = "URL you're trying to access is not valid."
      "HTTP/1.1 301 Moved Permanently\r\n" +
      "Location: /index.html\r\n" +
      "Content-Type: text/plain\r\n" +
      "Server: argos\r\n" +
      "Content-Length: #{message.length}\r\n" +
      "\r\n" +
      "#{message}"
    end
  end
end
