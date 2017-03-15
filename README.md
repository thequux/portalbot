Portal bot
==========

This is a slack bot that makes portals. It's useful for seamlessly
moving conversations to more appropriate channels.

Usage
-----

Create a custom bot integration for your slack team. Then, run 

    env SLACK_API_TOKEN=<token> bundle exec ./slack-portal.rb

Or, use the Docker image:

    docker run --restart=always -e SLACK_API_TOKEN=<token> thequux/portalbot:latest

