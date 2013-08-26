#require 'rubygems'
require 'sinatra'
require 'haml'
require 'bundler/setup'
require 'twilio-ruby'
require 'oauth'
require 'twitter'


enable :sessions

def round_to_precision(num, prec)
  num = num * (10 ** prec)
  num = num.round
  num = num.to_f / (10 ** prec).to_f
end

def is_number?
  self.to_f == self
end

def handle_weight
  session[:weight] = (params[:Body].partition(' ').last.to_f / 2.2) * 0.58
  if session[:weight].nil? == true
    handle_error.text
  elsif session[:weight] <20
    handle_error.text
  else
    handle_drinks_sms.text
  end
end

def handle_drinks
  session[:drinks] = params[:Body].partition(' ').last.to_f * 0.9672
  if session[:drinks].nil? == true
    handle_error.text
  elsif session[:drinks] <0.9
    handle_error_no_variable.text
  else
    handle_time_sms.text
  end
end

def handle_time
  session[:time] = params[:Body].partition(' ').last.to_f * 0.015
  if session[:time].nil? == true
    handle_error.text
  elsif session[:time] < 0.01
    handle_error.text
  else
    handle_bac
    handle_timeleft
    handle_hoursleft
    handle_minutesleft
    handle_bac_response.text
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
        if session[:bac].between?(1.39,10)
          r.Sms "Your BAC of #{session[:bac]} is higher than the highest recorded BAC."
        elsif session[:bac].between?(0.41,1.39)  
          r.Sms "Your BAC of #{session[:bac]} is near fatal.  In #{session[:hoursleft]} hrs #{session[:minutesleft]} mins you (may) be under the limit."
        elsif session[:bac].between?(0.081,0.4)  
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
    r.Sms "Almost there!!! Text time followed by how many hours you've been drinking"
  end
end
def handle_error
  swiml = Twilio::TwiML::Response.new do |r|
    r.Sms "Hmm, try that again.  I have no idea what you just input."
  end
end

def handle_error_no_variable
  twiml = Twilio::TwiML::Response.new do |r|
    r.Sms "Hmm, so how many drinks was that exactly?"
  end
end

def handle_tweetsent_sms
  fwiml = Twilio::TwiML::Response.new do |r|
    r.Sms "Your tweet was sent!  Check out the feed on Twitter @drunktxter."
  end
end

 
account_sid = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
auth_token = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
client = Twilio::REST::Client.new account_sid, auth_token
 
from = "+16506459938" # Your Twilio number
#Twitter Stuff
consumer_key = OAuth::Consumer.new(
  "xxxxxxxxxxxxxxxxxxx",
  "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
access_token = OAuth::Token.new(
  "xxxxxxxxxxxxxxxxxxx",
  "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")


Twitter.configure do |config|
  config.consumer_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  config.consumer_secret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  config.oauth_token = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  config.oauth_token_secret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
end

get '/' do
  
  # Make sure the text mesage has a body.
  if params[:Body].nil? == true
    halt 400
  else 
    @x = params[:Body].downcase
  end
  
   
  if @x.include?("beer") then
     handle_welcome_bac.text
  elsif @x.include?("weight")
     handle_weight
  elsif @x.include?("drinks")
     handle_drinks
  elsif @x.include?("time")
     handle_time
   elsif @x.include?("tweet")
     handle_twitterstatus
     Twitter.update(session[:twitter]+ "―BAC of #{session[:bac].to_s}") unless session[:twitter].nil?
     handle_tweetsent_sms.text
   else
     handle_error.text
   end
 end
  
