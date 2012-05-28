require 'core_ext/module/include'
# backports 1.9 style string interpolation. can be removed once hub runs in 1.9 mode
require 'i18n/core_ext/string/interpolate'

module Travis
  module Notifications
    module Handler

      # Publishes a build notification to campfire rooms as defined in the
      # configuration (`.travis.yml`).
      #
      # Campfire credentials are encrypted using the repository's ssl key.
      class Campfire
        API_VERSION = 'v2'

        EVENTS = /build:finished/

        include do
          attr_reader :build

          def notify(event, build, *args)
            @build = build # TODO move to initializer
            send(targets, payload) if send?
          end

          protected

            def send?
              build.send_campfire_notifications_on_finish?
            end

            def targets
              build.campfire_rooms
            end

            def payload
              Api.data(build, :for => 'notifications', :version => API_VERSION)
            end

            # TODO --- extract ---

            TEMPLATE = [
              "[travis-ci] %{slug}#%{number} (%{branch} - %{sha} : %{author}): the build has %{result}",
              "[travis-ci] Change view: %{compare_url}",
              "[travis-ci] Build details: %{build_url}"
            ]

            def send(targets, data)
              lines = message(data)
              targets.each { |target| send_lines(target, lines) }
            end

            def send_lines(target, lines)
              url, token = parse(target)
              client.basic_auth(token, 'X')
              lines.each { |line| send_line(url, line) }
            end

            def send_line(url, line)
              client.post(url) do |req|
                req.body = MultiJson.encode({ :message => { :body => line } })
                req.headers['Content-Type'] = 'application/json'
              end
            end

            def message(data)
              args = {
                :slug   => data['repository']['slug'],
                :number => data['build']['number'],
                :branch => data['commit']['branch'],
                :sha    => data['commit']['sha'][0..7],
                :author => data['commit']['author_name'],
                :result => data['build']['result'] == 0 ? 'passed' : 'failed',
                :compare_url => data['commit']['compare_url'],
                :build_url => "#{Travis.config.http_host}/#{data['repository']['slug']}/builds/#{data['build']['id']}"
              }
              TEMPLATE.map { |line| line % args }
            end

            def client
              @client ||= Faraday.new(http_options) do |f|
                f.adapter :net_http
              end
            end

            def http_options
              options = {}
              ssl = Travis.config.ssl
              options[:ssl] = { :ca_path => ssl.ca_path } if ssl.ca_path
              options[:ssl] = { :ca_file => ssl.ca_file } if ssl.ca_file
              options
            end

            def parse(target)
              target =~ /(\w+):(\w+)@(\w+)/
              ["https://#{$1}.campfirenow.com/room/#{$3}/speak.json", $2]
            end
        end
      end
    end
  end
end
