#!/usr/bin/env ruby

# To run this script you many need to do:#
# sudo gem install rsolr
#
# If using Ruby 1.8! 
# sudo gem install fastercsv   
#
# ruby simple_test.rb http://localhost:8983/solr/mbreleases ../mb_releases.csv
#

require 'rubygems'
if RUBY_VERSION > "1.9"
 require "csv"  
else
 require "fastercsv"
end

require 'rsolr'

if ARGV.empty? 
  puts "usage: ruby simple_test.rb <url> <csv_path>"
  puts " url similar to http://localhost:8983/solr/mbreleases"
  puts " csv_path similar to ../mb_releases.csv"
  
  exit
  
end

ARGV.each do|a|
  puts "Argument: #{a}"
end

BATCH_SIZE = 500  # how many documents to add at a time?  Try 1, 10, and 100.


url = ARGV[0].dup
csv_file_path = File.join(File.dirname(__FILE__), ARGV[1])

rsolr = RSolr.connect(:url => url)

rsolr.delete_by_query('*:*')
rsolr.commit

i = 0
documents = []
# Change CSV to FasterCSV if on Ruby 1.8
CSV.foreach( csv_file_path, :headers           => true,
                                  :header_converters => :symbol) do |line|
                                    
  i += 1

  doc = {}
  
  #id,type,r_name,r_a_id,r_a_name,r_attributes,r_tracks,r_lang,r_event_country,r_event_date,r_event_date_earliest
  attributes_to_split = [:r_attributes, :r_event_country, :r_event_date]
  attributes = line.headers - attributes_to_split
  attributes.each { |attribute| doc[attribute] = line[attribute]}
  attributes_to_split.each { |attribute| doc[attribute] = line[attribute].split unless line[attribute].nil? }
  
  documents << doc
  
  rsolr.add(documents) && documents.clear if i % BATCH_SIZE == 0

#  rsolr.commit if i % 200 == 0   # uncomment to test committing more frequently
#  rsolr.optimize if i % 1000 == 0 # uncomment to try out different points for optimizing
  puts i if i % BATCH_SIZE == 0
end
rsolr.add(documents)
rsolr.commit
