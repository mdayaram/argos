#!/usr/bin/env ruby

require 'socket'
require 'rubygems'
require 'httpclient'

module Argos
  class Resource

    def initialize(url, logger)
      @url = normalize(url)
      @logger = logger
    end

    def fetch(socket, resp_time = 5.0)
      log("Fetching resource: #{@url}")
      resp = HTTPClient.new.get(@url)
      result = "HTTP/#{resp.http_version} #{resp.status_code}\r\n"
      socket.print result
      log("Response: #{result.chomp}")

      log("Sending response headers.")
      headers, body = parse_response(resp)
      socket.print headers.join("\r\n")
      socket.print "\r\n\r\n"
      socket.flush

      if resp.status_code >= 400
        log("Response was >= 400, returning immediately.")
        socket.print body
        return
      end

      sleep_time, read_chunk = calculate_delay(resp_time, body.length)
      log("Sleep time per chunk: #{sleep_time}")
      log("Read chunk size: #{read_chunk} bytes")
      log("Content Length: #{body.length} bytes")

      if body.length == 0
        socket.print body
        return
      end

      body.bytes.to_a.each_slice(read_chunk) do |chunk|
        socket.print chunk.pack('C*')
        socket.flush
        sleep(sleep_time)
      end

    end

    private
    
    def log(msg)
      @logger.log(msg)
    end

    def parse_response(resp)
      body = resp.content
      headers = resp.headers.collect do |key, value|
        if key.downcase == "transfer-encoding" && value.downcase == "chunked"
          # Can't really handle chunked encoding, so will convert to normal...
          log("============CHUNKED ENCODED!================")
          log("#{key}: #{value}")
          "Content-Length: #{body.length}"
        else
          "#{key}: #{value}"
        end
      end
      [headers, body]
    end

    def calculate_delay(resp_time, content_len)
      return [0.1, 256] if content_len == 0

      sleep_time = 0.1
      read_chunk = Integer(content_len * sleep_time / resp_time)
      if read_chunk > 1024
        read_chunk = 1024
        sleep_time = Float(read_chunk * resp_time)/Float(content_len)
      end
      [sleep_time, read_chunk]
    end

    def normalize(uri)
      if uri.start_with?("http://") || uri.start_with?("https://")
        return uri
      elsif uri.start_with?("//")
        return "http:#{uri}"
      elsif uri.start_with?("/")
        return "http:/#{uri}"
      else
        return "http://#{uri}"
      end
    end
  end
end
