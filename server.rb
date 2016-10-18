require "sinatra"
require "pg"

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

def get_actors
  db_connection do |conn|
    sql_query = 'SELECT name, id FROM actors ORDER BY name'
    conn.exec(sql_query)
  end
end

def get_movies
  db_connection do |conn|
    sql_query = "SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    ORDER BY movies.title;"
    conn.exec(sql_query)
  end
end

# get '/movies?order=year' do
#   db_connection do |conn|
#     sql_query = "SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
#     FROM movies
#     LEFT JOIN genres ON movies.genre_id = genres.id
#     LEFT JOIN studios ON movies.studio_id = studios.id
#     ORDER BY movies.year;"
#     conn.exec(sql_query)
#   end
# end

get '/' do
  redirect "/actors"
end

get '/actors' do
  @actors = get_actors
  erb :'actors/index'
end

get '/actors/:id' do
  db_connection do |conn|
    sql_query = "SELECT actors.name, movies.title, movies.id, cast_members.character
    FROM cast_members
    JOIN movies ON cast_members.movie_id = movies.id
    JOIN actors ON cast_members.actor_id = actors.id
    WHERE actors.id = '#{params[:id]}';"
    @roles = conn.exec(sql_query)
  end
  erb :'actors/show'
end

get '/movies' do
  @movies = get_movies
  erb :'movies/index'
end

get '/movies/:id' do
  db_connection do |conn|
    sql_query = "SELECT movies.title, movies.year, movies.rating, actors.id AS actor_id, genres.name AS genre, studios.name AS studio, cast_members.character AS role, actors.name AS actor_name
    FROM movies
    JOIN genres ON movies.genre_id = genres.id
    JOIN studios ON movies.studio_id = studios.id
    JOIN cast_members ON movies.id = cast_members.movie_id
    JOIN actors ON cast_members.actor_id = actors.id
    WHERE movies.id = '#{params[:id]}';"
    @movie_info = conn.exec(sql_query)
  end
  erb :'movies/show'
end
