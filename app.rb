require 'rubygems'
require 'sinatra'
require 'haml'
require 'shotgun'
require 'bundler/setup'

def round_to_precision(num, prec)
  num = num * (10 ** prec)
  num = num.round
  num = num.to_f / (10 ** prec).to_f
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
