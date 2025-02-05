# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubi'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  session[:lists] ||= []
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    'The list name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'The list name must be unique.'
  end
end

get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [],  id: session[:lists].size }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Shows Todo lists name and any todos on that list
get '/lists/:list_id' do
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]

  erb :todos, layout: :layout
end

# Edit an existing todo list
get '/lists/:list_id/edit' do
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]
p @list
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post '/lists/:list_id' do
  list_name = params[:list_name].strip
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{list_id}"
  end
end

# GET  /lists      => view all lists
# GET / lists/new  => new list form
# POST /lists      => create new list
# GET  /lists/1    => view a single list
