# over to the working directory.
# Use the barebones version of Ruby 2.2.3.
FROM ruby:2.2.3-slim

# Optionally set a maintainer name to let people know who made this image.
MAINTAINER Nick Janetakis <nick.janetakis@gmail.com>
Run echo id
# Install dependencies:
# - build-essential: To ensure certain gems can be compiled
# - nodejs: Compile assets
# - libpq-dev: Communicate with postgres through the postgres gem
# - postgresql-client-9.4: In case you want to talk directly to postgres
RUN apt-get update && apt-get install -qq -y build-essential nodejs libpq-dev postgresql-client-9.4 --fix-missing --no-install-recommends

# Set an environment variable to store where the app is installed to inside
# of the Docker image.
ENV INSTALL_PATH /drkiq
RUN mkdir -p $INSTALL_PATH

# This sets the context of where commands will be ran in and is documented
# on Docker's website extensively.
WORKDIR $INSTALL_PATH

# Ensure gems are cached and only get updated when they change. This will
# drastically increase build times when your gems do not change.
COPY Gemfile Gemfile
RUN bundle install


# Copy in the application code from your work station at the current directory
COPY ./src .

# Provide dummy data to Rails so it can pre-compile assets.
RUN bundle exec rake RAILS_ENV=production DATABASE_URL=postgresql://user:pass@postgres/dbname SECRET_TOKEN=pickasecuretoken assets:precompile --trace

# Expose a volume so that nginx will be able to read in assets in production.
VOLUME ["$INSTALL_PATH/public"]

#Wait-for-postgres to initializw
COPY wait-for-postgres.sh /usr/local/bin/waitpostgres
RUN chmod +x /usr/local/bin/waitpostgres

# The default command that gets ran will be to start the Unicorn server.
#CMD bundle exec unicorn -c config/unicorn.rb
CMD ["waitpostgres", "postgres", "--", "bundle", "exec", "unicorn", "-c", "config/unicorn.rb"]
