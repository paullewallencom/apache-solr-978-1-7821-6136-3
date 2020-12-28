#!/usr/bin/env ruby

# To run this script you many need to do:#
# sudo gem install rsolr
#
# If using Ruby 1.8! 
# sudo gem install fastercsv   
#
# ruby threaded_test.rb 2000 4 http://localhost:8983/solr/mbreleases
#

require 'rubygems'
if RUBY_VERSION > "1.9"
 require "csv"  
else
 require "fastercsv"
end
require 'rsolr'

if ARGV.empty? 
  puts "usage: ruby threaded_test.rb <threads> <url> <csv_path>"
  puts " threads: Number of threads such as 4"
  puts " url: similar to http://localhost:8983/solr/mbreleases"
  puts " csv_path: similar to ../mb_releases.csv"

  exit
end

ARGV.each do|a|
  puts "Argument: #{a}"
end

BATCH_SIZE = 100  # how many documents to add at a time?  Try 1, 10, and 100.

thread_count = ARGV[0].dup.to_i
url = ARGV[1].dup
csv_file_path = File.join(File.dirname(__FILE__), ARGV[2].dup)

line_count = open(csv_file_path).read.count("\n") 

batch_count = line_count / thread_count

# Change CSV to FasterCSV if on Ruby 1.8
data = CSV.read(csv_file_path, :headers           => true,
                                :header_converters => :symbol)

rsolr = RSolr.connect(:url => url)

rsolr.delete_by_query('*:*')
rsolr.commit

threads = []
thread_count.times do |i|
  i = i + 1
  threads << Thread.new(i, data) { |myi, mydata|       
    
    starting_row = (myi * batch_count) - batch_count + 1
    ending_row = myi * batch_count
    puts "Thread #{myi}, #{starting_row}, #{ending_row}"
    
    thread_rsolr = RSolr.connect(:url => url)
    row_counter = 0
    documents = []
    mydata.each do |line|
      row_counter += 1

      #puts "[#{myi}] (#{row_counter}) #{line[:r_name]}"
      
      if row_counter >= starting_row and row_counter <= ending_row
        doc = {}

        #id,type,r_name,r_a_id,r_a_name,r_attributes,r_tracks,r_lang,r_event_country,r_event_date,r_event_date_earliest
        attributes_to_split = [:r_attributes, :r_event_country, :r_event_date]
        attributes = line.headers - attributes_to_split
        attributes.each { |attribute| doc[attribute] = line[attribute]}
        attributes_to_split.each { |attribute| doc[attribute] = line[attribute].split unless line[attribute].nil? }
  
        documents << doc
 
      end
      if documents.size >= BATCH_SIZE  # change this to a smaller number like 1 or 10 to see the performance difference
        thread_rsolr.add(documents) 
        documents = []
      end
      # rsolr.commit if row_counter % 200 == 0  # uncomment this to see impact of frequent commits!  Watch out for maxWarmingSearchers issue
      # rsolr.optimize unless row_counter.to_i%1000 != 0  #uncomment this to see impact of frequent optimizes
      puts "[#{myi}] #{row_counter}" if row_counter % 500 == 0
      
      
    end
    thread_rsolr.add(documents) unless documents.empty?
    thread_rsolr.commit
    puts "Ending Thread #{myi}"
  }
  
end

threads.each { |aThread|  aThread.join }


