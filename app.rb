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
  twiml = Twilio::TwiML::Response.new do |r|
    r.Sms "Hey, welcome to the bac app! What is your weight?"
  end
  session['m'] = params[:Body]to_f*5
  twiml.text
  redirect to('/hey')
 end
 
 get '/hey' do
   twiml = Twilio::TwiML::Response.new do |r|
   r.Sms "#{session['m']}"
   end 
   twiml.text
 end

get '/2ndquestion' do
  twiml = Twilio::TwiML::Response.new do |r|
  r.Sms "Hey, we have #{session[:m]} a second question! coolio!?"
  end 
  twiml.text
  end



get '/' do
  erb :anotherform
end

post '/' do
  x = (params[:weight].to_f / 2.2) * 0.58 
  y = params[:time].to_f * 0.015
  z = params[:drinks].to_f * 0.9672
  zz = round_to_precision((z/x-y),4)
  n = 40*(zz-0.08)/0.01
  h = (n / 60).floor 
  m = n - (h * 60)
  if zz >= 0.08
      "Your BAC of #{zz} is over the federal limit of 0.08. It will be #{h} hours and #{m} minutes before you are under the limit."
  elsif zz <0.08 
      "Your BAC of #{zz} is under the legal limit"
    end
end
