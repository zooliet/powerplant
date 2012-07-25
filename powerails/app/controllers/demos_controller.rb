require 'csv'

class Storage
  FFT_SIZE = 1024
  @previous = Array.new(FFT_SIZE)
  @current  = Array.new(FFT_SIZE)
  @max      = Array.new(FFT_SIZE)
  @min      = Array.new(FFT_SIZE)
  @average  = Array.new(FFT_SIZE)
  @diff     = Array.new(FFT_SIZE)
  
  class << self
    attr_accessor :previous, :current, :max, :min, :average, :diff
  end
  
  def self.fft
    file = "#{Rails.root}/log/adc.csv"
    current = CSV.readlines(file)[0].map {|v| v.to_f.round(2)}
    previous = CSV.readlines(file)[1].map {|v| v.to_f.round(2)}

    #  do some work here with those sampling data
    Storage::previous = Storage::FFT_SIZE.times.map { 30 + rand(30) }
    Storage::current  = Storage::FFT_SIZE.times.map { 30 + rand(30) }    
  end
end

class DemosController < ApplicationController
  # GET /demos
  # GET /demos.json
    
  def index
  end

  # GET /demos/1
  # GET /demos/1.json
  def show
    Storage.fft
    if params[:type] == "diff"
      # Storage::previous = Storage::FFT_SIZE.times.map { 30 + rand(30) }
      # Storage::current  = Storage::FFT_SIZE.times.map { 30 + rand(30) }
      render :json =>
            { :previous => Storage::previous, 
              :current  => Storage::current, 
              :interval => params[:interval],
              :type     => "difference"
            }
    else
      render :json =>
            { :previous => Storage::previous, 
              :current  => Storage::current, 
              :interval => params[:interval],
              :type     => "normal"
            }      
    end
  end

  # GET /demos/new
  # GET /demos/new.json
  def new
    @demo = Demo.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @demo }
    end
  end

  # GET /demos/1/edit
  def edit
    @demo = Demo.find(params[:id])
  end

  # POST /demos
  # POST /demos.json
  def create
    @demo = Demo.new(params[:demo])

    respond_to do |format|
      if @demo.save
        format.html { redirect_to @demo, notice: 'Demo was successfully created.' }
        format.json { render json: @demo, status: :created, location: @demo }
      else
        format.html { render action: "new" }
        format.json { render json: @demo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /demos/1
  # PUT /demos/1.json
  def update
    @demo = Demo.find(params[:id])

    respond_to do |format|
      if @demo.update_attributes(params[:demo])
        format.html { redirect_to @demo, notice: 'Demo was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @demo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /demos/1
  # DELETE /demos/1.json
  def destroy
    @demo = Demo.find(params[:id])
    @demo.destroy

    respond_to do |format|
      format.html { redirect_to demos_url }
      format.json { head :no_content }
    end
  end
end
