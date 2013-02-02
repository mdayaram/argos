#!/usr/bin/env ruby

module Argos
  class RequestLogger
    def log(msg)
      puts "rq[#{object_id}]: #{msg}"
    end
  end
end
