#!/usr/bin/ruby

require 'transmission-remote'

bt = TransmissionRemote.new('http://transmission:transmission@localhost:9091/transmission/rpc')

# Limit seed speed of downloading torrents in favor of seeing torrents:

# set max upload limit (in KB/sec) for all downloading torrents
bt.downloading.each { |t| t.uplimit(5) }

# set max upload limit (in KB/sec) for all seeding torrents
bt.seeding.each { |t| t.uplimit(100) }

# slow down perma-seeds
bt.seeding.each { |t|
    t.uplimit(5) if t['uploadRatio'] > 2
}
