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

def error_for_todo_item(item)
  return 'The todo must be between 1 and 100 characters.' unless (1..100).cover? item.size
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
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Shows Todo lists name and any todos on that list
get '/lists/:list_id' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  if @list.nil?
    session[:error] = 'The specified list does not exist.'
    redirect '/lists'
  else
    erb :todos, layout: :layout
  end
end

# Edit an existing todo list
get '/lists/:list_id/edit' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  if @list.nil?
    session[:error] = 'The specified list does not exist.'
    redirect '/lists'
  else
    erb :edit_list, layout: :layout
  end
end

# Update an existing todo list
post '/lists/:list_id' do
  list_name = params[:list_name].strip
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo list
post '/lists/:list_id/delete' do
  list_id = params[:list_id].to_i
  session[:lists].delete_at(list_id)
  session[:success] = 'The list has been deleted.'
  redirect '/lists'
end

# Add a new todo to a list
post '/lists/:list_id/todos' do
  todo_item = params[:todo].strip
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  error = error_for_todo_item(todo_item)
  if error
    session[:error] = error
    erb :todos, layout: :layout
  else
    @list[:todos] << { name: todo_item, completed: false }
    session[:success] = 'The todo was added.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post '/lists/:list_id/todos/:todo_id/delete' do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]

  todo_id = params[:todo_id].to_i
  list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{list_id}"
end


# GET   /                       => redirects to /lists
# GET   /lists                  => view all lists
# GET   /lists/new              => new list form
# POST  /lists                  => create new list
# GET   /lists/1                => view a single list
# GET   /lists/1/edit           => edit an existing list
# POST  /lists/1                => update an existing list
# POST  /lists/1/delete         => delete a todo list
# POST  /lists/1/todos          => add a new todo to a list
# POST  /lists/1/todos/0/delete => delete a todo from a list