class ArtistsController < ApplicationController
  # GET /artists
  # GET /artists.xml
  def index
    if params[:q]
      @artists = Artist.search{ keywords params[:q]}.results
    else
      @artists = Artist.paginate :page => params[:page], :order => 'created_at DESC'
    end
    
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @artists }
      format.json { render :json => @artists.to_json(:only => [:name, :id]), :callback => params[:callback] }
      
    end
  end

  # GET /artists/1
  # GET /artists/1.xml
  def show
    @artist = Artist.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @artist }
    end
  end

  # GET /artists/new
  # GET /artists/new.xml
  def new
    @artist = Artist.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @artist }
    end
  end

  # GET /artists/1/edit
  def edit
    @artist = Artist.find(params[:id])
  end

  # POST /artists
  # POST /artists.xml
  def create
    @artist = Artist.new(params[:artist])

    respond_to do |format|
      if @artist.save
        format.html { redirect_to(@artist, :notice => 'Artist was successfully created.') }
        format.xml  { render :xml => @artist, :status => :created, :location => @artist }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @artist.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /artists/1
  # PUT /artists/1.xml
  def update
    @artist = Artist.find(params[:id])

    respond_to do |format|
      if @artist.update_attributes(params[:artist])
        format.html { redirect_to(@artist, :notice => 'Artist was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @artist.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /artists/1
  # DELETE /artists/1.xml
  def destroy
    @artist = Artist.find(params[:id])
    @artist.destroy

    respond_to do |format|
      format.html { redirect_to(artists_url) }
      format.xml  { head :ok }
    end
  end
end
