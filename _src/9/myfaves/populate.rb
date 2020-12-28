#!/usr/bin/env ./script/rails runner

# the above shebang loads up the Rails environment giving us access to ActiveRecord.

puts "Populating MyFaves relational database from data in MusicBrainz Solr..."

MBARTISTS_SOLR_URL = 'http://localhost:8983/solr/mbartists'
BATCH_SIZE = 10
MAX_RECORDS = 100000   # the maximum number of records to load, or nil for all

solr_data = nil
offset = 0

rsolr = RSolr.connect :url => MBARTISTS_SOLR_URL

# turn off acts_as_solr managing Artist lifecycle while we load data.
#Artist.configuration[:offline] = true  

while true
  puts offset
  response = rsolr.select({
    :q => '*:*',
    :rows=> BATCH_SIZE, 
    :start => offset, 
    :fl => ['*','score']
  })
  
  break if response['response']['docs'].empty?  # at the end of the dataset available
  
  response['response']['docs'].each do |doc|
    id = doc["id"]
    id = id[7..(id.length)]
    a = Artist.new(
      :id => id,
      :name => doc["a_name"], 
      :group_type => doc["a_type"], 
      :release_date => doc["a_release_date_latest"]
    )
    begin
      a.save!
    rescue ActiveRecord::StatementInvalid => ar_si
      raise ar_si unless ar_si.to_s.include?("PRIMARY KEY must be unique") # sink duplicates
    end  
  end
  
  offset = offset + BATCH_SIZE
  
  unless MAX_RECORDS.nil?
    break if offset > MAX_RECORDS
  end
  
end
