FROM ruby:3.3

# Set environment
ENV BUNDLE_PATH=/gems \
    BUNDLE_APP_CONFIG=/gems/config \
    BUNDLE_BIN=/gems/bin \
    GEM_HOME=/gems \
    PATH="$BUNDLE_BIN:$PATH"

# Install OS dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs

# Set working directory
WORKDIR /app

# Copy Gemfiles first for caching
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the app
COPY . .

# Expose the port (Sinatra/Puma/Rack default)
EXPOSE 3000

# Default command
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "3000"]
