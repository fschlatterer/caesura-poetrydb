FROM ruby:3.1

RUN mkdir /poetrydb
COPY ./ /poetrydb
WORKDIR /poetrydb
RUN bundle install

EXPOSE 4567
CMD ["ruby", "poetrydb.rb"]
