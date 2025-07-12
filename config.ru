require './src/main'  # or 'main' depending on your file
# 🛡️ Allow requests from any host
set :trusted_hosts, nil
use Rack::Protection::HostAuthorization, hosts: nil
run Sinatra::Application
