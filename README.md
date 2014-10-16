sidekiq_graphite
==============

sidekiq stats to graphite

## prerequisities
* ruby 1.9.3+

## installation

* `git clone` of this repo
* run `bundle install`

## configuration

* move `config.yml.example` to `config.yml`
* edit `config.yml` file to add redis - sentinel servers
* change your prefix and graphite configuration

with `config.yml.example` - graphite metrics will look like - for example:

* `general.poll` means how many seconds is between each 'measurement'

## start

* make sidekiq_graphite.daemon executable `chmod 755 ./sidekiq_graphite.daemon`
* start with `./sidekiq_graphite.daemon start`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright @ 2014 Tom Meinlschmidt. See [MIT-LICENSE](https://github.com/tmeinlschmidt/sidekiq_graphite/blob/master/LICENSE) for details
