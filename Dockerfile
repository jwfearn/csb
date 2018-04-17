FROM ruby:2.5.1

ARG PROJECT_ROOT='/var/csb/'
ENV PROJECT_ROOT "${PROJECT_ROOT}"

WORKDIR "${PROJECT_ROOT}"

COPY . .

RUN curl -sL 'https://deb.nodesource.com/setup_9.x' | bash - \
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
    nodejs \
  && rm -rf /var/lib/apt/lists/* \
  && bundle install

ENTRYPOINT ["./test"]
