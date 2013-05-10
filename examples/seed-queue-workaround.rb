#!/usr/bin/ruby

require 'transmission-remote'

bt = TransmissionRemote.new('http://transmission:transmission@localhost:9091/transmission/rpc')

# workaround seed queue problem (bug #4617)
$seed_queue_size = 6

bt.
  seeding.sort {|a,b| a["queuePosition"] <=> b["queuePosition"]}. # list all seeds by queue order
  select {|t| t["status"] == "seed" }. # "seeding" lists both 'seed' and 'seed-wait', so select only non-queued seeds
  drop($seed_queue_size). # skip all torrents that should not be queued
  each{|t| t.pause; t.start;} # restart all seeds that should be queued - as described in the manual workaround for bug #4617
