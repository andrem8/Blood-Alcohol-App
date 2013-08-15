require 'rubygems'
require 'sinatra'
require 'haml'
require 'shotgun'
require 'bundler/setup'
require 'twilio-ruby'

enable :sessions

def round_to_precision(num, prec)
  num = num * (10 ** prec)
  num = num.round
  num = num.to_f / (10 ** prec).to_f
end

account_sid = "ACfa67ab7b63d3ae16a74365cd0cb14ae2"
auth_token = "f79e1d47cc1cc36ae5de4ead98b226b2"
client = Twilio::REST::Client.new account_sid, auth_token
 
from = "+16506459938" # Your Twilio number
 
get '/' do
  @x = params[:Body]
  
  if @x != nil
    twiml = Twilio::TwiML::Response.new do |r|
      r.Sms "Hey there! Welcome to the BAC app! Please text weight followed by well your weight"
    end
    session[:a] = (params[:Body].partition(' ').last.to_f / 2.2) * 0.58 if @x.include?("weight")
    himl = Twilio::TwiML::Response.new do |r|
      r.Sms "Cool, now text drinks followed by how many drinks you've had"
    end
    session[:b] = params[:Body].partition(' ').last.to_f * 0.9672 if @x.include?("drinks")
    timl = Twilio::TwiML::Response.new do |r|
      r.Sms "Almost there!!! Text time followed by how long have you been drinking"
    end
    session[:c] = params[:Body].partition(' ').last.to_f * 0.015 if @x.include?("time")
    subliml = Twilio::TwiML::Response.new do |r|
      bac = round_to_precision((session[:b]/session[:a]-session[:c]),4)
      timeleft = 40*(bac-0.08)/0.01
      hoursleft = (timeleft / 60).floor
      minutesleft = timeleft - (hoursleft * 60)
      if bac >= 0.08
        r.Sms "Your BAC of #{bac} is over the federal limit of 0.08.  It will be #{hoursleft} hours and #{minutesleft} minutes until you are under the limit"
      elsif bac.between?(0,0.079)
        r.Sms "Your BAC of #{bac} is under the limit"
      elsif bac < 0
        r.Sms "Have another beer"
      end
    end
    if @x.include?("drunk") then
      twiml.text
    elsif @x.include?("weight")
      himl.text
    elsif @x.include?("drinks")
      timl.text
    elsif @x.include?("time")
      subliml.text 
    end
  else
    swiml = Twilio::TwiML::Response.new do |r|
      r.Sms "Hmm, try something else"
    end
    swiml.text
  end
end



 

 
  
 


