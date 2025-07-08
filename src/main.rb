require 'dotenv/load'
require 'sinatra'
require 'uri'
require 'net/http'
require 'securerandom'
enable :sessions
set :port, ENV.fetch("PORT", 4567)  # Fallback to 4567 if PORT isn't set
set :bind, '0.0.0.0'                # Ensure it listens on all interfaces

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

def get_aquery_msg(index)
  case index
  when "1"
    "Success! sent to your slack DMs :3"
  when "2"
    "Invalid CSRF token. Please refresh the page"
  else
    "Unknown status"
  end
end

def post_message_to_slack(slack_id, message)
  uri = URI("https://slack.com/api/chat.postMessage")
  req = Net::HTTP::Post.new(uri)
  req['Content-Type'] = 'application/json'
  req['Authorization'] = "Bearer #{SLACK_TOKEN}"  # Make sure this is set!

  req.body = {
    channel: slack_id,
    text: message || ":neocat_shocked: No message provided"
  }.to_json

  # Send the request
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end

  puts "Slack API Response: #{res.body.inspect}"
  if res.is_a?(Net::HTTPSuccess) && JSON.parse(res.body)['ok']
    puts "✅ Message sent successfully to Slack user #{slack_id}"
  else
    puts "❌ Failed to send message to Slack user #{slack_id}: #{res.body}"
  end
end
def link_to_hackpad_tracking(email)
  puts "Airtable Key: #{AIRTABLE_TOKEN}, Base ID: #{AIRTABLE_BASE_ID}, Table Name: #{AIRTABLE_TABLE_NAME}"
    uri = URI("https://api.airtable.com/v0/#{AIRTABLE_BASE_ID}/#{AIRTABLE_TABLE_NAME}")
  
  params = {
    filterByFormula: "LOWER({email})='#{email.downcase}'",
    maxRecords: 1
  }

  uri.query = URI.encode_www_form(params)

  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{AIRTABLE_TOKEN}"
  req['Content-Type'] = 'application/json'

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end

  data = JSON.parse(res.body)
  puts "Airtable API Response: #{data.inspect}"
  if data['records'] && !data['records'].empty?
    return data['records'][0]['id']
  else
    return nil  # or raise "Not found"
  end
end
def notify_via_slack(email)
 
  uri = URI("https://slack.com/api/users.lookupByEmail?email=#{URI.encode_www_form_component(email)}")

  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{SLACK_TOKEN}"

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end

  data = JSON.parse(res.body)
  puts "Slack API Response: #{data.inspect}"
  if data["ok"]
    link_to_record = link_to_hackpad_tracking(email)
    user_id = data["user"]["id"]
   message = link_to_record ?
  ":neocat_3c: Here is the *permanent and public* link to your hackpad tracking status: https://prod/direct/" + link_to_record :
  ":neocat_sad: You weren't found in the hackpad tracking system, please contact support."

    
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
    <link href="https://cdn.jsdelivr.net/npm/daisyui@5" rel="stylesheet" type="text/css" />
<script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
<meta name="description" content="Get your hackpad tracking status with a simple form.">
    <meta name="keywords" content="hackpad, tracking, status, form, submit">
</head>
<body>
<div class="hero bg-base-200 min-h-screen">
  <div class="hero-content flex-col">
    <div class="text-center ">
      <h1 class="text-5xl font-bold">Get hackpad tracking status!</h1>
      <p class="py-6">
       Fill in your email here and then once you have submitted check your slack dms for a <b>permanent</b> link to your status.
      </p>
    </div>
    <div class="card bg-base-100 w-full max-w-sm shrink-0 shadow-2xl">
      <div class="card-body">
       #{" <div role='alert' class='alert #{aquery == "1" ? "alert-info" : "alert-error"} alert-soft'>
  <span>#{get_aquery_msg(aquery)}</span>
</div>" if aquery}
     <form action="/submit" method="post">
  <input type="hidden" name="authenticity_token" value="#{csrf_token}">
      <input type="hidden" name="confirmation_token" value="#{SecureRandom.hex(32)}">
      <input type="hidden" name="auth_token" value="#{SecureRandom.hex(32)}">
      <input type="hidden" name="rotation_token" value="#{SecureRandom.hex(32)}">
      <input type="hidden" name="2fa_token" value="#{SecureRandom.hex(64)}">
        <fieldset class="fieldset">
          <label class="label">Email</label>
          <input type="email" name="email" class="input" placeholder="Email" />
          <button class="btn btn-neutral mt-4">Login</button>
        </fieldset>
        </form>
      </div>
    </div>
  </div>
</div>
</body>
</html>
  HTML
end

post '/submit' do
  token = params[:authenticity_token]
  redirect "/?a=2" unless token == session[:csrf]
  puts "/submit"
  # Send silly willy slack dm here
  notify_via_slack(params[:email])
  # send back to index but with ?a= params
  redirect "/?a=1"
end

get '/direct/:id' do
  id = params[:id]
# get airtable record by id
  uri = URI("https://api.airtable.com/v0/#{AIRTABLE_BASE_ID}/#{AIRTABLE_TABLE_NAME}/#{id}")
  req = Net::HTTP::Get.new(uri)
  # pass headers
  req['Content-Type'] = 'application/json'
  req['Authorization'] = "Bearer #{AIRTABLE_TOKEN}"  # Make sure this is set!
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end
  data = JSON.parse(res.body)
  puts "Airtable API Response: #{data.inspect}"
  show_tracking = data['fields'] && data['fields']['tracking_number'] ? data['fields']['tracking_number'] : false
   <<~HTML
  <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Get hackpad tracking</title>
    <link href="https://cdn.jsdelivr.net/npm/daisyui@5" rel="stylesheet" type="text/css" />
<script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
<meta name="description" content="Get your hackpad tracking status with a simple form.">
    <meta name="keywords" content="hackpad, tracking, status, form, submit">
</head>
<body>
<div class="hero bg-base-200 min-h-screen">
  <div class="hero-content flex-col">
    <div class="text-center ">
      <h1 class="text-5xl font-bold">#{show_tracking ? "Tracking number" : "Nothing for you 3:" }</h1>
      <p class="py-6">
      #{show_tracking ? "Here is your tracking number: #{data['fields']['tracking_number']}" : "You have no tracking number or this record doesnt exist."}
      </p>
    </div>
  </div>
</div>
</body>
</html>
  HTML
end
