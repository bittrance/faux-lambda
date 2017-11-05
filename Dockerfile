FROM alpine:3.6

RUN apk --update add "ruby<2.4.3" git
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc && gem install bundler

WORKDIR /faux-lambda

COPY ./Gemfile Gemfile
COPY ./faux-lambda.gemspec faux-lambda.gemspec
COPY ./Gemfile.lock Gemfile.lock
COPY ./bin bin
COPY ./lib lib
RUN bundle install --deployment --without "development test" --path .gem --jobs 2

RUN adduser -h /faux-lambda -D worker
USER worker
EXPOSE 9123

ENTRYPOINT ["bundle", "exec", "./bin/faux-lambda", "--bind", "0.0.0.0"]
