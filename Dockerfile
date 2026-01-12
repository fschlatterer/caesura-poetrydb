FROM ruby:3.1

RUN mkdir /poetrydb
COPY ./ /poetrydb

# Install gems from the app directory (where Gemfile is)
WORKDIR /poetrydb/app
RUN bundle install

# Change back to root for running the application
WORKDIR /poetrydb

EXPOSE 4567
CMD ["ruby", "poetrydb.rb"]
