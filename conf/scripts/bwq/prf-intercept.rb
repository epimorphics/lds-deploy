#!/usr/bin/ruby

#
# Intercept a PRF CSV and check against existing incidents
# If any incidents match then rewrite PRF message but save
# copy of the original CSV to {file}-orig
#

require 'net/http'
require 'uri'
require 'json'
require 'pp'
require 'csv'
require 'fileutils'
require 'set'

#
# Support for fetching published pollution incidents
#
class PollutionIncidents 
  SERVER     = 'http://ea-rbwd-staging.epimorphics.net'
  #SERVER     = 'http://environment.data.gov.uk'
  PI_REQUEST = 'doc/bathing-water-quality/pollution-incident.json?_view=pollution-incident&_pageSize=100'

  @ok = false
  @data = nil

  def initialize; fetch; end

  def fetch
    request = URI( "#{SERVER}/#{PI_REQUEST}" )
    res = Net::HTTP.get_response(request)
    @ok = res.is_a?(Net::HTTPSuccess)
    @data = JSON.parse( res.body ) if @ok
  end

  def succeeded?; @ok; end

  def asJson; @data["result"]["items"]; end

  def incidents
    map = {}
    asJson.each do |incident|
      bw = sampling_point_from_bwid( incident["bathingWater"]["notation"] )
      msg = incident["incidentType"]["label"][0]["_value"]
      map[bw] = msg
    end
    map
  end

  def sampling_point_from_bwid(bwid)
    (bwid.match(/\w*-(\w*)/))[1]
  end

end

#
# Support for processing PRF csvs
#
class PRFCsv
  PRF_HEADERS = Set.new(["Site", "Datetime", "Prediction", "Prediction_text_en"])

  @rows
  @file

  def initialize( file )
    @file = file
    read_csv
  end

  def read_csv
    @rows = []
    CSV.foreach( @file, {:headers => true, :return_headers => true, :header_converters=> lambda {|f| f.strip}} ) do |row|
      @rows << row
    end
    @rows
  end

  def prf?
    @rows.size > 0 && PRF_HEADERS == Set.new( @rows[0].headers )
  end

  def map_csv( piMap )
    count = 0
    @rows[1..(@rows.size-1)].each do |row|
      msg = piMap[ row['Site'] ]
      if msg 
        row['Prediction'] = 2
        row['Prediction_text_en'] = "Risk of reduced water quality due to #{msg}"
        count = count+1
      end
    end
    count
  end

  def write
    write_as( @file )
  end

  def write_as( file )
    CSV.open( file, "wb") do |csvout| 
      @rows.each do |row|
        csvout << row
      end
    end
  end

  def file
    @file
  end

  def basename
    File.basename( @file )
  end

end

#
# Start of main execution
#
csv = PRFCsv.new( ARGV[0] )
if !csv.prf?
  puts "Skipping #{csv.basename}, not a PRF file"
  exit 0
end
puts "Checking PRF #{csv.basename}"

count = csv.map_csv( PollutionIncidents.new.incidents )
if count != 0
  FileUtils.cp( csv.file, "#{csv.file}-orig" )
  csv.write
end

puts "Done, #{count} forecasts intercepted"
exit( count == 0 ? 0 : 1 )
