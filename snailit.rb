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

def fetch_resource(socket, uri, logger)
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

  while str = resp.content.read(10)
    socket.print str
    socket.flush
    sleep(1)
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
          fetch_resource(socket, "http://#{url}", logger)
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
