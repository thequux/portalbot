require 'rubygems'
require 'bundler/setup'

require 'slack-ruby-client'
# require 'dotenv'
# Dotenv.load

class Slack::RealTime::Client
  def url_of data
    "https://#{team['domain']}.slack.com/archives/" + channels.find { |ch| ch["id"] == data['channel'] }["name"] + "/p" + data['ts'].delete('.')
  end
end

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

client = Slack::RealTime::Client.new

client.on :hello do
  puts "Successfully connected, welcome '#{client.self['name']}' to the '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com."
end

client.on :message do |data|
  unless client.self['id'] == data['user']
    case data['text']
    when /^bot/, /^portal/

      if data['text'] =~ /<#C.*?>/
        target_channel = data['text'][/<#(C.*?)>/, 1] 
        source_channel = data['channel']

        base_message = {unfurl_links: 'false', unfurl_media: 'false', as_user: 'true'}

        begin
          source_message = base_message.merge(channel: source_channel, text: "opening portal to <##{target_channel}>...")
          source_response = client.web_client.chat_postMessage(source_message)
        rescue Slack::Web::Api::Error => e
          client.web_client.chat_postMessage base_message.merge(channel: source_channel, text: "Encountered error: #{e}, in: immediate reply. Restarting...")
          return
        end

        begin
          target_message = base_message.merge(channel: target_channel, text: "portal from <##{source_channel}>:\n :blueportal: #{client.url_of(source_response)}")
          target_response = client.web_client.chat_postMessage(target_message)
        rescue Slack::Web::Api::Error => e
          if e.message == 'not_in_channel'
            client.web_client.chat_postMessage base_message.merge(channel: source_channel, text: "Encountered error: #{e}. I haven't been invited to <##{target_channel}> yet. Use the command `/invite @portal_bot` in that channel to invite me. Restarting...", mrkdown: 'true')
            return
          else  
            client.web_client.chat_postMessage base_message.merge(channel: source_channel, text: "Encountered error: #{e}, in: post to target channel. Restarting...")
            return
          end
        end

        begin
          client.web_client.chat_update(ts: source_response['ts'], channel: source_channel, text: "portal to <##{target_channel}>:\n :orangeportal: #{client.url_of(target_response)}")
        rescue Slack::Web::Api::Error => e
          client.web_client.chat_postMessage base_message.merge(channel: source_channel, text: "Encountered error: #{e}, in: update message. Restarting...")
          return
        end
      end
    end
  end
end

client.start!