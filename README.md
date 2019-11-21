# Outdated Article

Outdated Article is a simple GitHub bot made with [Sinatra](http://sinatrarb.com/) that helps you manage the outdated articles of your [Jekyll](https://jekyllrb.com) blog.

Check out the article on the [OmbuLabs blog](https://www.ombulabs.com/blog) for more details.

## Installation

The bot is available to install on the [GitHub Marketplace](https://github.com/marketplace/outdated-article).

## Development

### Requirements

Ruby >= 2.2.0

### Steps

1. Clone the repository to your local machine: `git clone git@github.com:ombulabs/outdated-article.git`
2. Go to the new directory and run `bundle`
3. Create a copy of the environment variables: `cp .env-example .env`
4. Add your GitHub App's private key, app ID, and webhook secret to the `.env` file.
5. Run `ruby server.rb`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ombulabs/outdated-article/issues.

## Support

You can contact hello@ombulabs.com if you have any question about this repository.
