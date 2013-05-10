#!/usr/bin/ruby

require 'transmission-remote'

bt = TransmissionRemote.new('http://transmission:transmission@localhost:9091/transmission/rpc')

$maxactive = 4

# add unfinished paused torrents until we have max torrents working
begin
  while bt.working.length < $maxactive
    # add torrents more likely to finish
    bt.waiting.sort { |a,b| a['leftUntilDone'] <=> b['leftUntilDone'] } [0].start
  end
rescue
end
