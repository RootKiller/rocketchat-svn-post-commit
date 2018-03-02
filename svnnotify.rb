#!/usr/bin/ruby -w

# RocketChat svn notification post-commit hook.
#

require 'net/http'
require 'json'
require 'openssl'
require 'kconv'

WEBHOOK_URL = "PASTE HERE YOUR WEB HOOK URL FROM ROCKET.CHAT ADMIN PANEL"

class String
  def toutf8byline
    result = ""
    each_line do |line|
      result += line.toutf8
    end
    result
  end
end

class SVNNotify
  def initialize()
    if ARGV.size < 2 then
      puts "Not enough params use svnnotify.rb <revision> <repos path>"
      abort
    end

    rev = ARGV[0].to_i
    repos = ARGV[1]

    # taken from commit-email.rb provided with svn
    # if you want more details in message you can use it

    svnauthor  = %x{/usr/local/bin/svnlook author #{repos} -r #{rev}}.chomp
    svndate    = %x{/usr/local/bin/svnlook date #{repos} -r #{rev}}.chomp
    svnchanged = %x{/usr/local/bin/svnlook changed #{repos} -r #{rev}}.chomp
    svnlog     = %x{/usr/local/bin/svnlook log #{repos} -r #{rev}}.toutf8byline.chomp
    svndiff    = %x{/usr/local/bin/svnlook diff #{repos} -r #{rev}}.toutf8byline.chomp

    sendMessage("[#{rev}] Author: #{svnauthor} - #{svndate}\n\n#{svnlog}")
  end

  def sendMessage(message)
    uri = URI(WEBHOOK_URL)

    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"

    bot_message = {
      :icon_emoji => ":ok:",
      :text => message
    }

    request.body = JSON.generate(bot_message)

    result = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  end

end

notify = SVNNotify.new
