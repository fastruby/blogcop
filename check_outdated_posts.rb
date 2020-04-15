require 'octokit'
require 'dotenv/load' # Manages environment variables
require 'json'
require 'openssl'     # Verifies the webhook signature
require 'jwt'         # Authenticates a GitHub App
require 'time'        # Gets ISO 8601 representation of a Time object
require 'logger'      # Logs debug statements
require 'byebug'

require_relative './repository_handler.rb'
require_relative './article_handler.rb'

class ArticlesChecker
  # Expects that the private key in PEM format. Converts the newlines
  PRIVATE_KEY = OpenSSL::PKey::RSA.new(ENV['GITHUB_PRIVATE_KEY'].gsub('\n', "\n"))

  # The GitHub App's identifier (type integer) set when registering an app.
  APP_IDENTIFIER = ENV['GITHUB_APP_IDENTIFIER']

  attr_reader :client

  # Instantiate an Octokit client authenticated as a GitHub App.
  # GitHub App authentication requires that you construct a
  # JWT (https://jwt.io/introduction/) signed with the app's private key,
  # so GitHub can be sure that it came from the app an not altererd by
  # a malicious third party.
  def authenticate_app
    payload = {
        # The time that this JWT was issued, _i.e._ now.
        iat: Time.now.to_i,

        # JWT expiration time (10 minute maximum)
        exp: Time.now.to_i + (10 * 60),

        # Your GitHub App's identifier number
        iss: APP_IDENTIFIER
    }

    # Cryptographically sign the JWT.
    jwt = JWT.encode(payload, PRIVATE_KEY, 'RS256')

    # Create the Octokit client, using the JWT as the auth token.
    @client ||= Octokit::Client.new(bearer_token: jwt)
  end

  # Instantiate an Octokit client, authenticated as an installation of a
  # GitHub App, to run API operations.
  def check_installations
    client.find_app_installations.each do |installation|
      # only work with our repos for now
      if %w[ombulabs fastruby].include?(installation[:account][:login])
        authenticate_installation(installation)

        # fetch repositories
        response = client.list_app_installation_repositories

        response[:repositories].each do |repository|
          # create a RepositoryHandler for each repository id
          # and check its articles
          RepositoryHandler.new(repository[:id], client).check_articles
        end
      end
    end
  end

  def authenticate_installation(installation)
    puts "Authenticating: #{installation[:account][:login]}"
    # clear token
    client.access_token = nil

    # get token for current installation
    token = client.create_app_installation_access_token(installation.id)

    # set token on client
    client.access_token = token.token    
  end
end

if __FILE__ == $0
  checker = ArticlesChecker.new
  checker.authenticate_app
  checker.check_installations
end