#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'sequel'
require 'sequel_secure_password'
require 'sinatra'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require 'haml'

DB = Sequel.connect 'sqlite://test.db'

DB.create_table? :users do
  primary_key :id
  String :name, unique: true, null: false
  String :password_digest, null: false
end

DB.create_table? :notes do
  primary_key :id
  String :message 
end

class Note < Sequel::Model; end


class User < Sequel::Model
  plugin :secure_password
  plugin :validation_helpers

  def validate
    super
    validates_unique :name
  end
end

enable :sessions

helpers do
  def authenticated!
    u = authenticated?
    halt 403, 'Not authorized' if u.nil?
    return u
  end

  def authenticated?
    return nil unless session.has_key? :userid
    User[session[:userid]]
  end
end

get '/' do
  haml :index
end

get '/login' do
  haml :login
end

post '/login' do
  user = User[name: params[:name]]
  redirect back, notice: 'Invalid username or password' if user.nil? or user.authenticate(params[:password]).nil?
  session[:userid] = user.id
  redirect '/', notice: 'You are now logged in!'
end

get '/register' do
  haml :register
end

get '/notes' do
  @notes = Note.all
  haml :notes
end

post '/notes' do
  note = Note.new
  note.message = params[:message]
  note.id = params[:id]
  note.save
  halt 201

end

get '/notes/:id/delete' do
  #Note.get(params[:id]).destroy 
  Note.where(id: params[:id]).delete
  redirect '/notes'
end

post '/register' do
  user = User.new
  user.name = params[:name]
  user.password = params[:password]
  user.password_confirmation = params[:password_confirmation]
  if not user.valid?
    user.errors.each { |field, error| flash[field] = "#{field}: #{error}" }
    redirect back
  end
  user.save
  redirect '/', notice: 'Successfully registered!'
end

post '/logout' do
  session.delete :userid
  redirect back, notice: 'Logged out!'
end
