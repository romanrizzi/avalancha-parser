# avalancha-parser

A parser for the avalancha language.

### Setup

- [Install rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer)
- Install ruby version by doing `rbenv install 2.6.5`
- `gem install bundler`
- Install dependencies: `bundle install`
- We use the `g++` command to compile the generated C++ code.

### Tasks

- `bundle exec rspec` to run tests.
- ` bundle exec rake "lex_file[path]"` to lex an specific file (e.g ` bundle exec rake "lex_file[examples/parser/test01.input]"`).
- ` bundle exec rake "parse_file[path]"` to parse an specific file (e.g ` bundle exec rake "parse_file[examples/parser/test01.input]"`).
- ` bundle exec rake "print_compiled[path]"` to print the generated C++ code (e.g ` bundle exec rake "parse_file[examples/codegen/5.input]"`).
- ` bundle exec rake "compile_and_run[path]"` generate the C++ and execute it, printing the result. (e.g ` bundle exec rake "compile_and_run[examples/codegen/13.input]"`).
