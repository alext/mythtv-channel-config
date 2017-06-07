#!/usr/bin/env ruby

require 'rubygems'
require 'rexml/document'
require 'mysql2'
require 'date'

HOME_CONFIG = "#{ENV['HOME']}/.mythtv/config.xml"
ETC_CONFIG = "/etc/mythtv/config.xml"
if File.exist?(HOME_CONFIG)
  file = HOME_CONFIG
elsif File.exist?(ETC_CONFIG)
  file = ETC_CONFIG
else
  raise "No config.xml found in #{HOME_CONFIG} or #{ETC_CONFIG}"
end
doc = REXML::Document.new(File.open(file, 'r'))

client = Mysql2::Client.new({
  :host => doc.elements.to_a("//Database/Host").first.text,
  :port => doc.elements.to_a("//Database/Port").first.text.to_i,
  :username => doc.elements.to_a("//Database/UserName").first.text,
  :password => doc.elements.to_a("//Database/Password").first.text,
  :database => doc.elements.to_a("//Database/DatabaseName").first.text,
})

File.open("channels_#{Date.today.to_s}.sql", 'w') do |f|
  client.query("SELECT * FROM channel ORDER BY chanid").each do |row|
    next if row["xmltvid"].to_s =~ /\A\s*\z/

    update_sql = "UPDATE channel SET xmltvid='#{row["xmltvid"]}', useonairguide=0"
    update_sql << ", commmethod=#{row['commmethod']}"
    update_sql << " WHERE callsign = '#{row["callsign"]}';"
    f.puts update_sql
  end
end
