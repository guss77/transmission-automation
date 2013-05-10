require 'net/http'
require 'uri'
require 'json'

class RemoteTorrent
        def initialize(remote, torrent)
                @remote = remote
                @torrent = torrent
                @torrent['status'] = case # tr_torrent_activity
                        when torrent['status'] == 1
                                'check-wait'
                        when torrent['status'] == 2
                                'check'
                        when torrent['status'] == 3
                                'download-wait'
                        when torrent['status'] == 4
                                'download'
                        when torrent['status'] == 5
                                'seed-wait'
                        when torrent['status'] == 6
                                'seed'
                        when torrent['status'] == 0
                                'stopped'
                        else
                                torrent['status']
                        end
        end

        def [](key)
                @torrent[key]
        end

        def pause
                @remote.pause(@torrent['id'])
        end

        def start
                @remote.start(@torrent['id'])
        end

        def uplimit(kb)
                @remote.uplimit(@torrent['id'],kb)
        end
end

class TransmissionRemote
        def initialize(uri)
                @uri = URI.parse(uri)
                @lastUpdate = Time.now - 60
        end

        def getTransmissionSID
                return @sid unless @sid.nil?
                http = Net::HTTP.new(@uri.host, @uri.port)
                request = Net::HTTP::Get.new(@uri.request_uri)
                request.basic_auth *@uri.userinfo.split(':')
                res = http.request(request)
                return @sid = res['x-transmission-session-id']
        end

        def allFields
                fields = <<FIELDS
activityDate addedDate
bandwidthPriority
comment corruptEver creator
dateCreated desiredAvailable doneDate downloadDir downloadedEver downloadLimit downloadLimited
error errorString eta
files fileStats
hashString haveUnchecked haveValid honorsSessionLimits
id isFinished isPrivate isStalled
leftUntilDone
manualAnnounceTime maxConnectedPeers magnetLink metadataPercentComplete name
percentDone peer-limit peers peersConnected peersFrom peersGettingFromUs peersSendingToUs pieces pieceCount pieceSize priorities
queuePosition
rateDownload rateUpload recheckProgress
seedIdleLimit seedIdleMode seedRatioLimit seedRatioMode sizeWhenDone startDate status secondsDownloading secondsSeeding
trackers trackerStats torrentFile totalSize
uploadedEver uploadLimit uploadLimited uploadRatio
wanted webseeds webseedsSendingToUs
FIELDS
                return fields.strip.split(/\s+/)
        end

        def remoteRequest(method, args)
                res = Net::HTTP.start(@uri.host,@uri.port) { |http|
                        req = Net::HTTP::Post.new(@uri.request_uri)
                        req.basic_auth *@uri.userinfo.split(':')
                        req['X-Transmission-Session-Id'] = getTransmissionSID
                        req.content_type = 'json'
                        req.body = JSON.generate({
                                "method" => method,
                                "arguments" => args
                                })
                        response = http.request(req)
                        response.value
                        result = JSON.parse(response.body)
                        raise "Transmission Failed" unless result['result'] == 'success'
                        result
                }
        end

        def getState
                @state = remoteRequest('torrent-get', { "fields" => allFields })
                @state['arguments']['torrents'] = @state['arguments']['torrents'].
                        collect { |t| RemoteTorrent.new(self, t) }
                @lastUpdate = Time.now
        end

        def validateState
                sleep 5 if @lastUpdate.nil?
                getState if @lastUpdate.nil? or @lastUpdate + 5 < Time.now
        end

        def pause(id)
                remoteRequest('torrent-stop', { "ids" => id })
                # invalidate state so the next query will see the changes
                lastUpdate = nil 
        end

        def start(id)
                remoteRequest('torrent-start', { "ids" => id })
                # invalidate state so the next query will see the changes
                lastUpdate = nil 
        end

        def uplimit(id,kb)
                if kb.nil?
                        remoteRequest('torrent-set',{ "ids" => id, 'uploadLimited' => false })
                else
                        remoteRequest('torrent-set',{ "ids" => id, 'uploadLimited' => true, 'uploadLimit' => kb })
                end
                lastUpdate = nil
        end

        def torrents
                validateState
                return @state['arguments']['torrents']
        end

        def downloading
                return torrents.find_all { |t| t['status'] == 'download' || t['status'] == 'download-wait' }
        end

        def paused
                return torrents.find_all { |t| t['status'] == 'stopped' }
        end

        def working
                return downloading.find_all { |t| t['desiredAvailable'] > 0 }
        end

        def waiting
                return paused.find_all { |t| t['percentDone'] < 1 }
        end

        def seeding
                return torrents.find_all { |t| t['status'] == 'seed' || t['status'] == 'seed-wait' }
        end
end
