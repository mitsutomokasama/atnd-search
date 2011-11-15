#encoding: utf-8

require 'uri'
require 'open-uri'
require 'json'
require 'date'
require 'sinatra'

before do
	@target_url = "http://api.atnd.org/events/?"
	@target_keyword = "keyword="
	@keyword = ""
	@data =  []
end

get '/' do
	haml :index
end

get '/result' do
	create_data(params[:keyword])
	haml :index
end

get '/error' do
	"エラーが発生しました"
end


private
def create_data(keyword)
	keyword_t = keyword.gsub(/^(¥s|　)|(¥s|　)$/, '').gsub(/¥s|　/, ',')
	if keyword_t.empty? then
		@target_keyword = ""
	else
		@target_keyword << URI::escape(keyword_t) + "&"
	end

	date = Date.today
	date.strftime('%Y%m')
	date = date.strftime('%Y%m')+ "," + (date >> 1).strftime('%Y%m') + "," + (date >> 2).strftime('%Y%m')

	@target_url << @target_keyword + "ym=" + date + "&count=100&format=json"
	@keyword = keyword
	json = parse_json(@target_url)
	@data = extract_data(json['events'])

	#debug
	#puts "keyword:" + keyword_t
	#puts "date:" + date
	#puts "api:" + @target_url
end

def parse_json(url)
	begin
		str = open(url) do |data|
			data.read
		end
	rescue
		redirect '/error'
	end

	begin
		json = JSON.parse(str)
	rescue
		redirect '/error'
	end
	json
end

def extract_data(data)
	redirect '/error' if data.empty?

	result = []
	data.each do |v|
		hash = {}
		hash['title'] 		= v['title']
		hash['event_url'] 	= v['event_url']
		hash['started_at']	= v['started_at']
		hash['accepted']	= v['accepted']
		hash['limit']		= v['limit']
		result.push hash
	end
	result = result.sort{|a,b|
		a['started_at'] <=> b['started_at']
	}
end
