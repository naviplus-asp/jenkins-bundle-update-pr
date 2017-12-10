# Jenkins::Bundle::Update::Pr

jenkins-bundle-update-pr is a script for continues bundle update. Use in Jenkins.

Both concept and implementaion are strongly based on [circleci-bundle-update-pr](https://github.com/masutaka/circleci-bundle-update-pr).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jenkins-bundle-update-pr'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jenkins-bundle-update-pr

## Usage

    $ jenkins-bundle-update-pr 'Git username' 'Git email address'

By default, it works only on master branch, but you can also explicitly specify any branches rather than only master branch by adding them to the arguments.

    $ jenkins-bundle-update-pr 'Git username' 'Git email address' master develop topic

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/naviplus-asp/jenkins-bundle-update-pr. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Jenkins::Bundle::Update::Pr project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/jenkins-bundle-update-pr/blob/master/CODE_OF_CONDUCT.md).
