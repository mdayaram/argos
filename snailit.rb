#!/usr/bin/env ruby

require 'socket'
require 'optparse'
require 'rubygems'
require 'httpclient'

options = { :port => 4567 }
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options]"
  opts.on("-p", "--port N", Integer, "Port to start the server on, default is 4567") do |port|
    options[:port] = port
  end
end.parse!

class RequestLogger
  def initialize
    log("Got a request! How exciting!")
  end

  def log(msg)
    puts "rq[#{object_id}]: #{msg}"
  end
end

def generate_response(message, status_code = 200, content_type = "text/plain")
  "HTTP/1.1 #{status_code}\r\n" +
  "Content-Type: #{content_type}\r\n" +
  "Content-Length: #{message.length}\r\n" +
  "\r\n" +
  message
end

def fix_uri(uri)
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

def fetch_resource(socket, uri, logger)
  uri = fix_uri(uri)
  client = HTTPClient.new
  logger.log("Getting resource: #{uri}")
  resp = client.get_async(uri).pop
  result = "HTTP/#{resp.http_version} #{resp.status_code}\r\n"
  logger.log("Response: #{result.chomp}")
  socket.print result
  socket.print resp.headers.collect { |key, value| "#{key}: #{value}\r\n" }.join
  socket.print "\r\n"

  if resp.status_code >= 400
    socket.print resp.content.read
    return
  end
  content_len = resp.headers['Content-Length'].to_i

  response_len = 5.0
  sleep_time = 0.1
  read_chunk = Integer(content_len * sleep_time / response_len)
  if read_chunk > 1024
    read_chunk = 1024
    sleep_time = Float(read_chunk * response_len)/Float(content_len)
  end

  while str = resp.content.read(read_chunk)
    socket.print str
    socket.flush
    sleep(sleep_time)
  end
end


puts "Starting server on 0.0.0.0:#{options[:port]}"
webserver = TCPServer.new('0.0.0.0', options[:port])

loop do
  Thread.start(webserver.accept) do |socket|

    logger = RequestLogger.new
    begin
      request = socket.gets
      logger.log("Request: #{request}")
      if request =~ /^GET \/(.*?)\s+HTTP\/\d\.\d\r\n$/i
        url = $1
        if url == "" || url == "index.html"
          socket.print generate_response(File.read("./index.html"), 200, "text/html")
        elsif url == "favicon.ico"
          socket.print generate_response("Nope", 404, "")
        else
          fetch_resource(socket, url, logger)
        end
      else
        socket.print generate_response("You failed.")
      end
    rescue StandardError => e
      logger.log "Error handling request: #{e.inspect}"
    end
    logger.log("Completed request.")
    socket.close
  end
end
puts "Server shutting down..."
