#!/usr/bin/env ruby
# See LICENSE for the needlessly onerous conditions this file is
# licensed under.

require 'rubygems'
require 'bundler/setup'

require 'slack-ruby-client'
# require 'dotenv'
# Dotenv.load

class Slack::RealTime::Client
  def url_of data
    "https://#{team['domain']}.slack.com/archives/" + channels[data['channel']].name + "/p" + data['ts'].delete('.')
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
    when /^portal (from|to) <#(C[^|>]*?)(?:\|[^>]*)?>/
      match = /^portal (from|to) <#(C[^|>]*?)(?:\|[^>]*)?>/.match(data['text'])
      
      target_channel = match[2]
      source_channel = data['channel']
      if match[1] == 'from'
        target_channel, source_channel = source_channel, target_channel
      end

      base_message = {unfurl_links: 'false', unfurl_media: 'false', as_user: 'true'}

      begin
        source_message = base_message.merge(channel: source_channel, text: "opening portal to <##{target_channel}>...")
        source_response = client.web_client.chat_postMessage(source_message)
      rescue Slack::Web::Api::Error => e
        client.web_client.chat_postMessage base_message.merge(channel: source_channel, text: "Encountered error: #{e}, in: immediate reply. Restarting...")
        next
      end

      begin
        target_message = base_message.merge(channel: target_channel, text: "portal from <##{source_channel}>:\n :blueportal: #{client.url_of(source_response)}")
        target_response = client.web_client.chat_postMessage(target_message)
      rescue Slack::Web::Api::Error => e
        if e.message == 'not_in_channel'
          client.web_client.chat_postMessage base_message.merge(channel: source_channel, text: "Encountered error: #{e}. I haven't been invited to <##{target_channel}> yet. Use the command `/invite @portal_bot` in that channel to invite me. Restarting...", mrkdown: 'true')
          next
        else  
          client.web_client.chat_postMessage base_message.merge(channel: source_channel, text: "Encountered error: #{e}, in: post to target channel. Restarting...")
          next
        end
      end

      begin
        client.web_client.chat_update(ts: source_response['ts'], channel: source_channel, text: "portal to <##{target_channel}>:\n :orangeportal: #{client.url_of(target_response)}")
      rescue Slack::Web::Api::Error => e
        client.web_client.chat_postMessage base_message.merge(channel: source_channel, text: "Encountered error: #{e}, in: update message. Restarting...")
        next
      end
    end
  end
end

client.start!
