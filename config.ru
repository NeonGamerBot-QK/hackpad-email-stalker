require './src/main'  # or 'main' depending on your file
set :trusted_hosts, nil
use Rack::Protection::HostAuthorization, hosts: nil
run Sinatra::Application
