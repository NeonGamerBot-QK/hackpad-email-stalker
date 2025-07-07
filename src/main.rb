require 'dotenv/load'
require 'sinatra'
require 'uri'
require 'net/http'
require 'securerandom'
enable :sessions

SLACK_TOKEN = ENV["SLACK_TOKEN"]
AIRTABLE_TOKEN= ENV["AIRTABLE_TOKEN"]
AIRTABLE_BASE_ID= ENV["AIRTABLE_BASE_ID"]
AIRTABLE_TABLE_NAME = ENV["AIRTABLE_TABLE_NAME"]
# uri = URI('https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY')
# res = Net::HTTP.get_response(uri)
# puts res.body if res.is_a?(Net::HTTPSuccess)
helpers do
  def csrf_token
    session[:csrf] ||= SecureRandom.hex(32)
  end
end

def post_message_to_slack(slack_id, message)
  uri = URI("https://slack.com/api/chat.postMessage")
  req = Net::HTTP::Post.new(uri)
  req['Content-Type'] = 'application/json'
  req.body ={
    "channel": slack_id,
    "text": message || ":neocat_shocked: No message provided"
  }
end
def link_to_hackpad_tracking(email)

end
def notify_via_slack(email)
 
  uri = URI("https://slack.com/api/users.lookupByEmail?email=#{URI.encode_www_form_component(email)}")

  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{SLACK_TOKEN}"

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end

  data = JSON.parse(res.body)
  # puts "Slack API Response: #{data.inspect}"
  if data["ok"]
    link_to_record = link_to_hackpad_tracking(email)
    user_id = data["user"]["id"]
    message = ":neocat_3c: Here is the *permanent and public* link to your hackpad tracking status: " if link_to_record else ":neocat_sad: You werent found in the hackpad tracking system, please contact support."
    
    post_message_to_slack(user_id, message)
  else
    puts "Error fetching user by email: #{data['error']}"
  end
end
get '/' do
  aquery = params[:a]
  <<~HTML
  <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Get hackpad tracking</title>
</head>
<body>
     <form action="/submit" method="post">
      <input type="hidden" name="authenticity_token" value="#{csrf_token}">
      <input type="hidden" name="confirmation_token" value="#{SecureRandom.hex(32)}">
      <input type="hidden" name="auth_token" value="#{SecureRandom.hex(32)}">
      <input type="hidden" name="rotation_token" value="#{SecureRandom.hex(32)}">
      <input type="hidden" name="2fa_token" value="#{SecureRandom.hex(64)}">
      <input type="email" name="email">
      <button type="submit">Submit</button>
    </form>
</body>
</html>
  HTML
end

post '/submit' do
  token = params[:authenticity_token]
  halt 403, "Forbidden: Invalid CSRF token" unless token == session[:csrf]
  puts "/submit"
  # Send silly willy slack dm here
  notify_via_slack(params[:email])
  # send back to index but with ?a= params
  redirect "/?a=1"
end

