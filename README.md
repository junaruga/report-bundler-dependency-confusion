# report-bundler-dependency-confusion

A reproducer for https://github.com/rubygems/rubygems/issues/4694 .

The reproducer store the following gem on the 2 gem servers.

```
tmp/
└── repos
    ├── 8801 - a-0.0.2
    └── 8802 - a-0.0.1, b-1.0.0
```

Then run the `bundle install` with the following `Gemfile`.

```
$ cat Gemfile
source "http://127.0.0.1:8801"
# The gem 'b' has a runtime dependency gem 'a'.
gem "b", source: "http://127.0.0.1:8802"
```

## Run the script.

You can run the script with the `bundle` from the upstream repository or installed `bundle` command.
Modify `TEST_BUNDLE` in the `test.sh` if you want to adjust the upstream RubyGems repository path to run the `ruby /path/to/rubygems/bundler/spec/support/bundle.rb`.

Here is the log. The `a` gem version 0.0.2 that is indirect dependency in the `Gemfile` is installed from the public repo (port 8801).

```
$ ./test.sh
...
+ ruby /home/jaruga/git/rubygems/bundler/spec/support/bundle.rb install
Fetching source index from http://127.0.0.1:8802/
Fetching source index from http://127.0.0.1:8801/
Resolving dependencies...
Using bundler 2.3.0.dev
Fetching a 0.0.2
Installing a 0.0.2
Fetching b 1.0.0
Installing b 1.0.0
Bundle complete! 1 Gemfile dependency, 3 gems now installed.
Bundled gems are installed into `./app`
+ ruby /home/jaruga/git/rubygems/bundler/spec/support/bundle.rb info a
  * a (0.0.2)
    Summary: a
    Homepage: https://dev.null
    Path: /home/jaruga/var/git/report-bundler-dependency-confusion/app/ruby/3.0.0/gems/a-0.0.2
...
```
