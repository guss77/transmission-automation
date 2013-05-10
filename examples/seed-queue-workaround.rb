#!/usr/bin/ruby

require 'transmission-remote'

bt = TransmissionRemote.new('http://transmission:transmission@localhost:9091/transmission/rpc')

# workaround seed queue problem (bug #4617)
$seed_queue_size = 6

bt.seeding.sort {|a,b| a["queuePosition"] <=> b["queuePosition"]}.select {|t| t["status"] == "seed" }.drop($seed_queue_size).each{|t| t.pause; t.start;}
