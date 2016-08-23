web: bundle exec puma -p 5000
redis: redis-server --port $REDIS_PORT
resque_scheduler: bundle exec rake resque:scheduler
resque_worker: bundle exec rake resque:work
mongo: bundle exec mongod --dbpath=$MONGO_PATH --rest
