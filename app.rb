require 'rubygems'
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
  weight = (params[:Body].partition(' ').last.to_f / 2.2) * 0.58
  if weight == false
    puts "error"
  elsif weight < 0
    puts "error"
    session[:weight]
  end
end

def handle_drinks
  drinks = params[:Body].partition(' ').last.to_f * 0.9672
  if drinks == false
    puts "error"
  elsif weight < 0
    puts "error"
    session[:drinks]
  end
end

def handle_tweet
  twitter = params[:Body].partition(' ').last
  if twitter == false
    puts "error"
  else
    session[:twitter]
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
  if @x.include?("weight")
    handle_weight
  end
  
    
  if @x.nil? == true
    puts "changed something!"
  else
    session[:a] = (params[:Body].partition(' ').last.to_f / 2.2) * 0.58 if @x.include?("weight")
    session[:b] = params[:Body].partition(' ').last.to_f * 0.9672 if @x.include?("drinks")
    session[:c] = params[:Body].partition(' ').last.to_f * 0.015 if @x.include?("time")
    
    citylocate = params[:FromCity]
    if session[:a].nil? == true && @x.include?("drunk") == true
      twiml = Twilio::TwiML::Response.new do |r|
          r.Sms "Hey there! Welcome to the BAC app! Please text weight followed by well your weight"
        end
      twiml.text
    elsif session[:b].nil? == true && @x.include?("weight") == true
      himl = Twilio::TwiML::Response.new do |r|
        r.Sms "Cool, now text drinks followed by how many drinks you've had"
        end
      himl.text
    elsif session[:c].nil? == true && @x.include?("drinks") == true
      timl = Twilio::TwiML::Response.new do |r|
        r.Sms "Almost there!!! Text time followed by how long have you been drinking"
        end
      timl.text
    elsif @x.include?("time") == true
      bac = round_to_precision(session[:b]/session[:a]-session[:c],3)
      timeleft = 40*(bac-0.08)/0.01 
      hoursleft = (timeleft / 60).floor 
      minutesleft = (timeleft - (hoursleft.floor * 60)).floor 
  
      subliml = Twilio::TwiML::Response.new do |r| 
        if bac >= 0.08  
          r.Sms "Your BAC of #{round_to_precision(bac, 2)} is over 0.08.  In #{hoursleft} hrs #{minutesleft} mins you (may) be under the limit. Text tweet and a message!"
        elsif bac.between?(0,0.08)
          r.Sms "Your BAC of #{round_to_precision(bac, 2)} is under the limit"
        elsif bac.between?(-0.5,0)
          r.Sms "Have another beer"
        end
      end
      subliml.text
    elsif @x.include?("twitter")
      request.set_form_data(
        "status" => "hey")
      request.oauth! http, consumer_key, access_token
      response = http.request request
    else 
    
    bac = round_to_precision(session[:b]/session[:a]-session[:c],3)
    timeleft = 40*(bac-0.08)/0.01 
    hoursleft = (timeleft / 60).floor 
    minutesleft = (timeleft - (hoursleft.floor * 60)).floor 
  
    subliml = Twilio::TwiML::Response.new do |r| 
      if bac >= 0.08  
        r.Sms "Your BAC of #{round_to_precision(bac, 2)} is over 0.08.  In #{hoursleft} hrs #{minutesleft} mins you (may) be under the limit. Text tweet and a message!"
      elsif bac.between?(0,0.08)
        r.Sms "Your BAC of #{round_to_precision(bac, 2)} is under the limit"
      elsif bac.between?(-0.5,0)
        r.Sms "Have another beer"
      end
    end

    twiml = Twilio::TwiML::Response.new do |r|
        r.Sms "Hey there! Welcome to the BAC app! Please text weight followed by well your weight"
      end
    himl = Twilio::TwiML::Response.new do |r|
      r.Sms "Cool, now text drinks followed by how many drinks you've had"
      end
    timl = Twilio::TwiML::Response.new do |r|
      r.Sms "Almost there!!! Text time followed by how long have you been drinking"
      end
    swiml = Twilio::TwiML::Response.new do |r|
      r.Sms "Hmm, try something else"
    end
    
     if @x.include?("drunk") then
        twiml.text 
     elsif @x.include?("weight")
        himl.text
     elsif @x.include?("drinks")
        timl.text
     elsif @x.include?("time")
        subliml.text
     elsif @x.include?("tweet")
       request.set_form_data(
         "status" => "hey")
       request.oauth! http, consumer_key, access_token
       response = http.request request
      end
    end
  end
end
