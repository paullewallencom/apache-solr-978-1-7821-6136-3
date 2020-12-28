#!/usr/bin/env ruby

# gem sources -a http://gems.github.com
# sudo gem install fastercsv
# sudo gem install mwmitchell-rsolr

#
# ruby threaded_test.rb 2000 4 http://ec2-72-44-43-64.compute-1.amazonaws.com:8983/solr/mbreleases
#

require 'rubygems'
require 'fastercsv'
require 'rsolr'
require 'pp'

if ARGV.empty? 
  puts "usage: ruby shard_indexer.rb <csv_path>"
  puts " csv_path: similar to ../mb_releases.csv"
  puts "don't forget to set the SHARDS constant value in the script"
  break
end

ARGV.each do|a|
  puts "Argument: #{a}"
end

# Array of URL's to each shard.
SHARDS = ['http://ec2-174-129-178-110.compute-1.amazonaws.com:8983/solr/mbreleases', 
          'http://ec2-75-101-213-59.compute-1.amazonaws.com:8983/solr/mbreleases']

csv_file_path = File.join(File.dirname(__FILE__), ARGV[0])

puts "Begin parsing CSV"
t = Time.now
data = FasterCSV.read(csv_file_path, :headers           => true,
                                :header_converters => :symbol)
puts "Done parsing CSV, took #{Time.now - t} seconds"                                

threads = []
thread_id = 0
SHARDS.each do |shard_url|
  
  threads << Thread.new(thread_id, data, shard_url) { |local_thread_id, mydata, myshard_url|       
    
  
    puts "Thread #{local_thread_id}, #{myshard_url}"
    
    myrsolr = RSolr.connect(:url => myshard_url)
    myrsolr.adapter.connector.adapter_name = :net_http
    
    response = myrsolr.select(:q=>'*:*')
    myrsolr.delete_by_query('*:*')
    myrsolr.commit
    
    row_counter = 0
    documents = []
    mydata.each do |line|
      row_counter += 1
      unique_id = line[:id]
      
      # determine if the id matches the current thread's shard.  If so, index it.
      if unique_id.hash % SHARDS.size == local_thread_id 
        doc = {}

        #id,type,r_name,r_a_id,r_a_name,r_attributes,r_tracks,r_lang,r_event_country,r_event_date,r_event_date_earliest
        attributes_to_split = [:r_attributes, :r_event_country, :r_event_date]
        attributes = line.headers - attributes_to_split
        attributes.each { |attribute| doc[attribute] = line[attribute]}
        attributes_to_split.each { |attribute| doc[attribute] = line[attribute].split unless line[attribute].nil? }
  
        documents << doc
 
      end
      if documents.size >= 500  # change this to a smaller number like 1 or 10 to see the performance difference
        myrsolr.add(documents) 
        documents = []
      end
      myrsolr.commit if row_counter % 20000 == 0  # uncomment this to see impact of frequent commits!  Watch out for maxWarmingSearchers issue
      # rsolr.optimize unless row_counter.to_i%10000 != 0  #uncomment this to see impact of frequent optimizes
      puts "[#{local_thread_id}] #{row_counter}" if row_counter % 500 == 0
      
      
    end
    myrsolr.add(documents) unless documents.empty?
    myrsolr.commit
    puts "Ending Thread #{local_thread_id}"
  }
  thread_id += 1
  
end

threads.each { |aThread|  aThread.join }


