require 'bundler/setup'
require 'sinatra'
require 'haml'
require 'pony'

enable :sessions

MONTH = 30*24*60*60 unless defined? MONTH

configure :development do
  require 'sinatra/reloader'
  Pony.options = {
    :from => ENV['CONTACT_FROM_STRING'],
    :via => :sendmail
  }
end

configure :production do
  before do
    set :static_cache_control, [:public, :max_age => 1 * MONTH]
  end
  Pony.options = {
    :from => ENV['CONTACT_FROM_STRING'],
    :via => :smtp,
    :via_options => {
      :address => 'smtp.sendgrid.net',
      :port => '587',
      :domain => 'heroku.com',
      :user_name => ENV['SENDGRID_USERNAME'],
      :password => ENV['SENDGRID_PASSWORD'],
      :authentication => :plain,
      :enable_starttls_auto => true
    }
  }
end

get '/' do
  @error = session.delete(:error)
  haml :index
end

get '/thanks' do
  haml :thanks
end

post '/mail' do
  if params[:name].blank? || params[:email].blank? || params[:message].blank?
    session[:error] = "All fields are required."
    redirect '/'
  end
  body = "Name: #{params[:name]}\n\nEmail: #{params[:email]}\n\n#{params[:message]}"
  Pony.mail(
    to: ENV['CONTACT_TO_STRING'],
    subject: "Contact from #{request.host} website",
    body: body
  )
  redirect 'thanks'
end

not_found do
  status 404
  "Not found"
end

error do
  status 500
  "Server error"
end