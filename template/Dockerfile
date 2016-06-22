FROM ruby:2.3-alpine
RUN apk add --no-cache --virtual bash
RUN apk add --no-cache --virtual git
ENV APP_HOME /__APP_NAME__
ENV PATH $APP_HOME:$PATH
RUN mkdir -p $APP_HOME/
WORKDIR $APP_HOME/
COPY . $APP_HOME/
COPY bashrc /root/.bashrc
CMD ["/__APP_NAME__/docker/bin/cmd"]
