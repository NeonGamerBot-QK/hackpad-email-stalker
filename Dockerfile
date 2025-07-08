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

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy app source
COPY . .

# Expose the port only if your app opens one
EXPOSE 4567

# Run your Ruby script directly
CMD ["ruby", "src/main.rb"]
