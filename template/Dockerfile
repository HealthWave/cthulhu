FROM ruby:2.3-alpine
RUN apk add --no-cache --virtual bash
RUN apk add --no-cache --virtual git
RUN apk add --no-cache --virtual alpine-sdk
ENV APP_HOME /__APP_NAME__
ENV PATH $APP_HOME:$PATH
RUN mkdir -p $APP_HOME/
WORKDIR $APP_HOME/
COPY Gemfile* $APP_HOME/
RUN bundle install
COPY . $APP_HOME/
COPY docker/files/bashrc /root/.bashrc
CMD ["cthulhu", "s"]
