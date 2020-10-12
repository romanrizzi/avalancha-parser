# avalancha-parser

A parser for the avalancha language.

### Setup

- [Install rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer)
- Install ruby version by doing `rbenv install 2.6.5`
- `gem install bundler`
- Install dependencies: `bundle install`

### Tasks

- `bundle exec rspec` to run tests.
- ` bundle exec rake "lex_file[path]"` to lex an specific file (e.g ` bundle exec rake "lex_file[examples/test01.input]"`).
- ` bundle exec rake "parse_file[path]"` to parse an specific file (e.g ` bundle exec rake "parse_file[examples/test01.input]"`).
