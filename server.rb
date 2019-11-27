require 'sinatra'
require 'octokit'
require 'dotenv/load' # Manages environment variables
require 'json'
require 'openssl'     # Verifies the webhook signature
require 'jwt'         # Authenticates a GitHub App
require 'time'        # Gets ISO 8601 representation of a Time object
require 'logger'      # Logs debug statements
require 'byebug'
require 'httparty'

class Blogcop < Sinatra::Application

  # Expects that the private key in PEM format. Converts the newlines
  PRIVATE_KEY = OpenSSL::PKey::RSA.new(ENV['GITHUB_PRIVATE_KEY'].gsub('\n', "\n"))

  # Your registered app must have a secret set. The secret is used to verify
  # that webhooks are sent by GitHub.
  WEBHOOK_SECRET = ENV['GITHUB_WEBHOOK_SECRET']

  # The GitHub App's identifier (type integer) set when registering an app.
  APP_IDENTIFIER = ENV['GITHUB_APP_IDENTIFIER']

  OUTDATED_MONTHS = 3
  MAIN_BRANCH = 'master'

  # Turn on Sinatra's verbose logging during development
  configure :development do
    set :logging, Logger::DEBUG
  end


  # Before each request to the `/event_handler` route
  before '/event_handler' do
    get_payload_request(request)
    verify_webhook_signature
    authenticate_app
    # Authenticate the app installation in order to run API operations
    authenticate_installation(@payload)
  end


  post '/event_handler' do
    case request.env['HTTP_X_GITHUB_EVENT']
    when 'push'
      unpublish_outdated_articles if push_made_to_master
    end

    200 # success status
  end


  helpers do
    def push_made_to_master
      @payload['ref'] == 'refs/heads/master'
    end

    def unpublish_outdated_articles
      articles = @client.contents(repository, path: '_posts')

      articles.each do |article|
        @article = article
        commits = @client.commits(repository, MAIN_BRANCH, path: @article[:path])
        last_commit_date = commits.first[:commit][:committer][:date].to_date

        if last_commit_date < expiration_date
          puts "#{@article[:path]} is outdated"

          next if branch_already_created

          create_branch
          push_commit
          create_pull_request
          create_issue
        end
      end
    end

    def expiration_date
      Date.today << OUTDATED_MONTHS
    end

    def repository
      @payload['repository']['full_name']
    end

    def branch_already_created
      branches = @client.refs(repository, nil, per_page: 100).map(&:ref)
      branch = "refs/heads/#{branch_name}"
      branches.include?(branch)
    end

    def branch_name
      "unpublish/#{@article[:name]}"
    end

    def last_commit_on_master
      @client.commits(repository, MAIN_BRANCH).first
    end

    def create_branch
      puts 'Creating Branch'

      @client.create_ref(
        repository,
        "heads/#{branch_name}",
        last_commit_on_master[:sha])
    end

    def create_pull_request
      puts 'Creating Pull Request'

      @client.create_pull_request(
        repository,
        MAIN_BRANCH,
        branch_name,
        pull_request_title,
        pull_request_body)
    end

    def pull_request_title
      'Unpublish outdated article'
    end

    def pull_request_body
      "This PR unpublishes the article `#{@article[:path]}` because " +
      "its last update was more than #{OUTDATED_MONTHS} months ago."
    end

    def create_issue
      puts 'Creating Issue'

      begin
        @client.create_issue(repository, issue_title, issue_body)
      rescue Octokit::ClientError => error
        # Issues can be disabled in the repository settings so this can fail.
        puts error
      end
    end

    def issue_title
      "#{@article[:path]} needs to be updated"
    end

    def issue_body
      "`#{@article[:path]}` has been marked as unpublished and needs to be updated"
    end

    def push_commit
      puts 'Pushing commit'

      @client.update_contents(
        repository,
        @article[:path],
        'Unpublish outdated article',
        @article[:sha],
        unpublished_body,
        branch: branch_name)
    end

    def unpublished_body
      article_body.gsub(article_header, unpublished_header)
    end

    def article_body
      HTTParty.get(@article[:download_url]).body
    end

    def article_header
      article_body[/#{'---'}(.*?)#{'---'}/m, 1]
    end

    def unpublished_header
      headers_attributes = article_header.split("\n")
      unpublished = 'published: false'

      headers_attributes.map! do |attribute|
        attribute.include?('published:') ? unpublished : attribute
      end

      unless headers_attributes.include?(unpublished)
        headers_attributes << unpublished
      end

      unpublished_header ||= headers_attributes.join("\n") + "\n"
    end

    # Saves the raw payload and converts the payload to JSON format
    def get_payload_request(request)
      # request.body is an IO or StringIO object
      # Rewind in case someone already read it
      request.body.rewind
      # The raw text of the body is required for webhook signature verification
      @payload_raw = request.body.read
      begin
        @payload = JSON.parse @payload_raw
      rescue => e
        fail  "Invalid JSON (#{e}): #{@payload_raw}"
      end
    end

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
      @app_client ||= Octokit::Client.new(bearer_token: jwt)
    end

    # Instantiate an Octokit client, authenticated as an installation of a
    # GitHub App, to run API operations.
    def authenticate_installation(payload)
      @installation_id = payload['installation']['id']
      @installation_token = @app_client.create_app_installation_access_token(@installation_id)[:token]
      @client = Octokit::Client.new(bearer_token: @installation_token)
    end

    # Check X-Hub-Signature to confirm that this webhook was generated by
    # GitHub, and not a malicious third party.
    #
    # GitHub uses the WEBHOOK_SECRET, registered to the GitHub App, to
    # create the hash signature sent in the `X-HUB-Signature` header of each
    # webhook. This code computes the expected hash signature and compares it to
    # the signature sent in the `X-HUB-Signature` header. If they don't match,
    # this request is an attack, and you should reject it. GitHub uses the HMAC
    # hexdigest to compute the signature. The `X-HUB-Signature` looks something
    # like this: "sha1=123456".
    # See https://developer.github.com/webhooks/securing/ for details.
    def verify_webhook_signature
      their_signature_header = request.env['HTTP_X_HUB_SIGNATURE'] || 'sha1='
      method, their_digest = their_signature_header.split('=')
      our_digest = OpenSSL::HMAC.hexdigest(method, WEBHOOK_SECRET, @payload_raw)
      halt 401 unless their_digest == our_digest

      # The X-GITHUB-EVENT header provides the name of the event.
      # The action value indicates the which action triggered the event.
      logger.debug "---- received event #{request.env['HTTP_X_GITHUB_EVENT']}"
      logger.debug "----    action #{@payload['action']}" unless @payload['action'].nil?
    end

  end

  # Finally some logic to let us run this server directly from the command line,
  # or with Rack. Don't worry too much about this code. But, for the curious:
  # $0 is the executed file
  # __FILE__ is the current file
  # If they are the same—that is, we are running this file directly, call the
  # Sinatra run method
  run! if __FILE__ == $0
end
