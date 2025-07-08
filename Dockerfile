# Dockerfile
FROM ruby:3.3

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 3.3.5 && bundle install

COPY . .

CMD ["bundle", "exec", "ruby", "src/main.rb"]
