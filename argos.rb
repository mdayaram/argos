#!/usr/bin/env ruby

require 'optparse'
require 'socket'
require './argos/logger'
require './argos/server'
require './argos/handler'
require './argos/resource'

options = { :port => 4567, :address => "0.0.0.0" }
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options]"
  opts.on("-p", "--port N", Integer, "Port to bind the server on, default is 4567") do |port|
    options[:port] = port
  end
  opts.on("-a", "--address ADDRESS", "The address to bind to, default is 0.0.0.0") do |address|
    options[:address] = address
  end
end.parse!

Argos::Server.new(options[:address], options[:port]).run
