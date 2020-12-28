require 'rubygems'
require 'csv'
require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

if 1==1
  # Return the 100,000 most popular artists based on track lookups, and filters out duplicates using field collapsing.
  SOLR_URL = "http://localhost:8983/solr/mbtracks/select/?rows=1000&q=*:*&defType=edismax&qf=t_name&boost=sum(recip(t_trm_lookups,0.0000111,-0.75,0.5),1.5,2)&wt=json&fl=t_a_name&indent=true&group=true&group.field=t_a_name&group.main=true"

  results = JSON.parse(Net::HTTP.get URI.parse(SOLR_URL))


  CSV.open("seed_data_step_1.csv", "wb") do |csv|
    results["response"]["docs"].each{|doc| csv << [doc["t_a_name"]]}
  end
end

if 1 == 1
  CSV.open("seed_data_step_2.csv", "wb") do |csv|
    CSV.foreach("seed_data_step_1.csv") do |row|
     artist = row[0]
     begin
       doc = Nokogiri::Slop(Net::HTTP.get URI.parse("http://www.musicbrainz.org/ws/2/artist?query=#{URI.escape(artist)}"))
       artists = doc.xpath('//xmlns:artist')
     
       id = artists.first['id'] unless artists.nil?
       csv << [id] unless id.nil?
     rescue Exception => ex
       
     end
    end
  end
end


if 1 == 1
  CSV.open("seed_data_step_3.csv", "wb") do |csv|
    CSV.foreach("seed_data_step_2.csv") do |row|
     mbid = row[0]
     begin
       doc = Nokogiri::Slop(Net::HTTP.get URI.parse("http://www.musicbrainz.org/ws/2/artist/#{mbid}?inc=url-rels"))
       url = doc.xpath("//xmlns:relation[@type='wikipedia']").first.text
       csv << [url] unless url.nil?
     rescue Exception => ex

     end
    end
  end
end
