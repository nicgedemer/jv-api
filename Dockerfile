FROM ruby:2.6.3

COPY app /app

WORKDIR /app

RUN gem install bundler -v 2.0.2 && bundle install

EXPOSE 4567

# Setting CMD via Fargate/ECS
# CMD ["bundle", "exec", "ruby", "simpsons_simulator.rb", "-p", "4567", "-o", "0.0.0.0"]