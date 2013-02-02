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
      resp = HTTPClient.new.get_async(@url).pop
      result = "HTTP/#{resp.http_version} #{resp.status_code}\r\n"
      socket.print result
      log("Response: #{result.chomp}")

      log("Sending response headers.")
      headers, chunked = get_headers(resp)
      socket.print headers.join("\r\n")

      if chunked
        body = resp.content.read
        socket.print "Content-Length: #{body.length}\r\n"
        socket.print "\r\n"
        socket.print body
        return
      end

      socket.print "\r\n\r\n"
      socket.flush

      if resp.status_code >= 400
        log("Response was >= 400, returning immediately.")
        socket.print resp.content.read
        return
      end

      content_len = content_length(resp)
      sleep_time, read_chunk = calculate_delay(resp_time, content_len)
      log("Sleep time per chunk: #{sleep_time}")
      log("Read chunk size: #{read_chunk} bytes")
      log("Content Length: #{content_len} bytes")

      if content_len == 0
        body = resp.content.read
        puts "body: #{body}"
        socket.print body
        return
      end

      while chunk = resp.content.read(read_chunk)
        puts "chunk: #{chunk}"
        socket.print chunk
        socket.flush
        sleep(sleep_time)
      end
    end

    private
    
    def log(msg)
      @logger.log(msg)
    end

    def get_headers(resp)
      chunked_encoded = false
      headers = resp.headers.collect do |key, value|
        if key.downcase == "transfer-encoding" && value.downcase == "chunked"
          # Can't really handle chunked encoding, so will convert to normal...
          chunked_encoded = true
        else
          "#{key}: #{value}"
        end
      end
      [headers, chunked_encoded]
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

    def content_length(response)
      response.headers.each do |key, value|
        if key =~ /^Content-Length$/i
          return value.to_i
        end
      end
      0
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
