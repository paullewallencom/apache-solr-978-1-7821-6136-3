require 'uri'
class MyfavesController < ApplicationController
  before_filter :myfaves
  def index

  end

  def create
    begin
      @artist = Artist.find(params[:artist][:id])
    rescue ActiveRecord::RecordNotFound
    end
    
    if @artist.nil?
      flash[:notice] = "Artist matching #{params[:artist][:name]} was not found."
    else
      if @artist.image_url.nil?
        @artist.image_url = find_artist_image(@artist.name)
        @artist.save!
      end
      @myfaves << @artist
      @myfaves.uniq!
    end

    redirect_to :action => :index
    
  end

  def show
    #fixme this shoudl be a destroy method not a show method!
    @artist = Artist.find(params[:id])

    @myfaves.delete @artist

    redirect_to :action => :index
  end  
  
protected
  def myfaves
    unless session[:myfaves]
      session[:myfaves] = []
    end
    @myfaves = session[:myfaves]    
  end
  
  def find_artist_image(name)
    name = URI.escape(name)

    resp = Net::HTTP.get_response(URI.parse("http://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=#{name}"))

    result = ActiveSupport::JSON.decode(resp.body)    
      
    return result['responseData']['results'].first['url'] unless result['responseData']['results'].size == 0

  end
end
