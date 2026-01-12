FROM ruby:3.1

RUN mkdir /poetrydb
COPY ./ /poetrydb

WORKDIR /poetrydb/app
RUN bundle install

EXPOSE 3000
CMD ["bundle", "exec", "unicorn", "-p", "3000", "-c", "unicorn.rb"]
