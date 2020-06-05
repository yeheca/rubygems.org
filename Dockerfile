FROM ruby:2.6-alpine as build

ARG RUBYGEMS_VESION

RUN apk add --no-cache \
  ruby \
  nodejs \
  postgresql-client \
  postgresql-dev \
  ca-certificates \
  ruby-dev \
  build-base \
  bash \
  linux-headers \
  zlib-dev \
  libxml2-dev \
  libxslt-dev \
  tzdata \
  && rm -rf /var/cache/apk/*

RUN mkdir -p /app /app/config /app/log/
WORKDIR /app

RUN gem update --system $RUBYGEMS_VERSION

COPY . /app

ADD https://s3-us-west-2.amazonaws.com/oregon.production.s3.rubygems.org/versions/versions.list /app/config/versions.list

RUN mv /app/config/database.yml.example /app/config/database.yml

RUN gem install bundler io-console --no-doc && bundle install --jobs 20 --retry 5 --without deploy

RUN RAILS_ENV=production SECRET_KEY_BASE=1234 bin/rails assets:precompile




FROM ruby:2.6-alpine

ARG RUBYGEMS_VERSION

RUN apk add --no-cache \
  ruby \
  nodejs \
  postgresql-client \
  ca-certificates \
  bash \
  tzdata \
  xz-libs \
  && rm -rf /var/cache/apk/*

RUN gem update --system $RUBYGEMS_VERSION

RUN mkdir -p /app
WORKDIR /app

COPY --from=build /usr/local/bin/gem /usr/local/bin/gem
COPY --from=build /usr/local/bundle/ /usr/local/bundle/
COPY --from=build /app/ /app/

EXPOSE 3000

ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server", "-b", "0.0.0.0"]
