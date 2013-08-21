#require 'rubygems'
require 'sinatra'
require 'haml'
require 'bundler/setup'
require 'twilio-ruby'
require 'oauth'

enable :sessions

def round_to_precision(num, prec)
  num = num * (10 ** prec)
  num = num.round
  num = num.to_f / (10 ** prec).to_f
end

def handle_weight
  session[:weight] = (params[:Body].partition(' ').last.to_f / 2.2) * 0.58
  if session[:weight].nil? == true
    puts "error"
  end
end

def handle_drinks
  session[:drinks] = params[:Body].partition(' ').last.to_f * 0.9672
  if session[:drinks].nil? == true
    puts "error"
  end
end

def handle_time
  session[:time] = params[:Body].partition(' ').last.to_f * 0.015
  if session[:time].nil? == true
    puts "error"
  end
end

def handle_citylocate
  session[:citylocate] = params[:FromCity]
  if session[:citylocate].nil? == true
    puts "citylocate error"
  end
end

def handle_twitterstatus
  session[:twitter] = params[:Body].partition(' ').last
  if session[:twitter].nil? == true
    puts "error"
  end
end

def handle_bac
  session[:bac] = round_to_precision(session[:drinks]/session[:weight]-session[:time],3)
    if session[:bac].nil? == true
      puts "error"
    end
end

def handle_timeleft
  session[:timeleft] = 40*(session[:bac]-0.08)/0.01
  if session[:timeleft].nil? == true
    puts "timeleft error"
  end
end

def handle_hoursleft
  session[:hoursleft] = (session[:timeleft] / 60).floor 
  if session[:hoursleft].nil? == true
    puts "hoursleft error"
  end
end

def handle_minutesleft
  session[:minutesleft] = (session[:timeleft] - (session[:hoursleft].floor * 60)).floor 
  if session[:minutesleft].nil? == true
    puts "minutesleft error"
  end
end

def handle_bac_response
  subliml = Twilio::TwiML::Response.new do |r| 
    if session[:bac] == nil
      puts "error terror"
    else
        if session[:bac] >= 0.08  
          r.Sms "Your BAC of #{session[:bac]} is over 0.08.  In #{session[:hoursleft]} hrs #{session[:minutesleft]} mins you (may) be under the limit. Text tweet and a message!"
        elsif session[:bac].between?(0,0.08)
          r.Sms "Your BAC of #{session[:bac]} is under the limit"
        elsif session[:bac].between?(-0.5,0)
          r.Sms "Have another beer"
        end
    end
  end
end
 
def handle_welcome_bac
  twiml = Twilio::TwiML::Response.new do |r|
    r.Sms "Hey there! Welcome to the BAC app! Please text weight followed by well your weight"
  end
end
def handle_drinks_sms
  himl = Twilio::TwiML::Response.new do |r|
    r.Sms "Cool, now text drinks followed by how many drinks you've had"
  end
end
def handle_time_sms
  timl = Twilio::TwiML::Response.new do |r|
    r.Sms "Almost there!!! Text time followed by how long have you been drinking"
  end
end
def handle_error
  swiml = Twilio::TwiML::Response.new do |r|
    r.Sms "Hmm, try something else"
  end
end

 
account_sid = "ACfa67ab7b63d3ae16a74365cd0cb14ae2"
auth_token = "f79e1d47cc1cc36ae5de4ead98b226b2"
client = Twilio::REST::Client.new account_sid, auth_token
 
from = "+16506459938" # Your Twilio number
#Twitter Stuff
consumer_key = OAuth::Consumer.new(
  "KgVEEBIltLRA8PxK2vzTQ",
  "kGGE4u3gcRf89l21GxinXopblPTh06vTNVft6QYTU")
access_token = OAuth::Token.new(
  "1674434030-5eLHRjST9620ptSpE845YdVt3OGtz7LNOdGkZdd",
  "H0sR8hiRU5vSkqPJvpUflRdxvEQPjvmAxuaq3xfnxI")

#MoreTwitter Stuff #justrealizedoriginsofhashtag
baseurl = "https://api.twitter.com"
path    = "/1.1/statuses/update.json"
address = URI("#{baseurl}#{path}")
request = Net::HTTP::Post.new address.request_uri

http             = Net::HTTP.new address.host, address.port
http.use_ssl     = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
http.start

get '/' do
  
  # Make sure the text mesage has a body.
  if params[:Body].nil? == true
    halt 400
  else 
    @x = params[:Body].downcase
  end
  
   
  if @x.include?("drunk") then
     handle_welcome_bac.text
  elsif @x.include?("weight")
     handle_weight
     handle_drinks_sms.text
  elsif @x.include?("drinks")
     handle_drinks
     handle_time_sms.text
  elsif @x.include?("time")
     handle_time
     handle_bac
     handle_timeleft
     handle_hoursleft
     handle_minutesleft
     handle_bac_response.text
   elsif @x.include?("tweet")
     handle_bac
     handle_citylocate
     handle_twitterstatus
     request.set_form_data(
       "status" => "#{session[:twitter].to_s }"+" \##{session[:bac].to_f}")
     request.oauth! http, consumer_key, access_token
     response = http.request request
   end
 end
  