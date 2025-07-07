require 'dotenv/load'
require 'sinatra'
require 'uri'
require 'net/http'
require 'securerandom'

enable :sessions
# uri = URI('https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY')
# res = Net::HTTP.get_response(uri)
# puts res.body if res.is_a?(Net::HTTPSuccess)
helpers do
  def csrf_token
    session[:csrf] ||= SecureRandom.hex(32)
  end
end

get '/' do
  stream do |out|
    out << File.read('public/index.html')
  end
end

get '/_render_form' do
  <<~HTML
    <form action="/submit" method="post">
      <input type="hidden" name="authenticity_token" value="#{csrf_token}">
      <input type="hidden" name="authenticity_token2" value="#{SecureRandom.hex(32)}">
      <input type="hidden" name="authenticity_token3" value="#{SecureRandom.hex(32)}">
      <input type="hidden" name="authenticity_token4" value="#{SecureRandom.hex(32)}">
      <input type="hidden" name="2fa_token" value="#{SecureRandom.hex(64)}">
      <input type="email" name="email">
      <button type="submit">Submit</button>
    </form>
  HTML
end

post '/submit' do
  token = params[:authenticity_token]
  halt 403, "Forbidden: Invalid CSRF token" unless token == session[:csrf]
  # Send silly willy slack dm here
  # send back to index but with ?a= params
  redirect "/?a=1"
end

