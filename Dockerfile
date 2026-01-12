# Change FROM ruby:2.6.0 to:
FROM ruby:3.1

RUN apt-get update && apt-get install -y mongodb-clients
RUN mkdir /poetrydb
COPY ./ /poetrydb
WORKDIR /poetrydb/app
RUN bundle install

EXPOSE 4567
CMD ["ruby", "poetrydb.rb"]
