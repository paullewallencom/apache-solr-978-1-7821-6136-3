#!/usr/bin/env ruby

# This script is inspired by "check_solr_slave.rb" script by Bryan McLellan <btm@loftninjas.org>
# http://exchange.nagios.org/directory/Plugins/Java-Applications-and-Servers/check_solr_slave/details

# You may need to run gem install hpricot

require 'uri'
require 'net/http'
require 'optparse'
require 'date'
require 'hpricot'

# Set default options
options = {}
options[:hostname] = "localhost"
options[:port] = "8983"
options[:core] = "mbartists"
options[:warn] = "15"
options[:crit] = "30"

# Parse command line options
opts = OptionParser.new
opts.on('-H', '--hostname [hostname]', 'Host to connect to [localhost]') do |hostname|
  options[:hostname] = hostname
end
  
opts.on('-p', '--port [port]', 'Port to connect to [8983]') do |port|
  options[:port] = port
end

opts.on('-i', '--core [core]', 'Core to connect to [mbartists]') do |core|
  options[:core] = core
end

opts.on('-w', '--warn [milliseconds]', 'Threshold for warning [30]') do |warn|
  options[:warn] = warn
end

opts.on('-c', '--crit [milliseconds]', 'Threshold for critical [60]') do |crit|
  options[:crit] = crit
end

opts.on( '-h', '--help', 'Display this screen' ) do
  puts opts
  exit 3
end
opts.parse!

# Fetch statistics data from solr in XML  
res = Net::HTTP.start(options[:hostname], options[:port]) do |http|
  http.get("/solr/#{options[:core]}/admin/mbeans?stats=true&wt=xml")
end

unless res.code == "200"
  puts "CRITICAL - Unable to contact solr: HTTP #{res.code}"
  exit 2
end 

# Parse stats elements 
doc = Hpricot(res.body)

documentCacheStats = doc.at("//name[text()='documentCache']").parent
standardRequestHandlerStats = doc.at("//name[text()='standard']").parent


hitratio = documentCacheStats.at("//stat[@name='hitratio']").inner_html.to_f
avgTimePerRequest = standardRequestHandlerStats.at("//stat[@name='avgTimePerRequest]").inner_html.to_f

if hitratio < 0.90 and hitratio > 0.0
  puts "WARNING - document cache hit ratio is #{hitratio}"
  exit 1
elsif avgTimePerRequest > options[:crit].to_i
  puts "CRITICAL - Average Time per request more than #{options[:crit]} milliseconds old: #{avgTimePerRequest}"
  exit 2
elsif avgTimePerRequest > options[:warn].to_i
  puts "WARNING - Average Time per request more than #{options[:warn]} milliseconds old: #{avgTimePerRequest}"
  exit 1
else
  puts "OK - Solr looks great." 
  exit 0
end

