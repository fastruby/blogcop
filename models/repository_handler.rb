MAIN_BRANCH = 'master'
OUTDATED_MONTHS = 3

class RepositoryHandler
  def initialize(repo_id, client)
    @repo_id = repo_id
    @client = client
    @expiration_date = Date.today << OUTDATED_MONTHS
  end

  def check_articles
    # get all articles inside _posts
    articles_data = @client.contents(@repo_id, path: '_posts')
    
    articles_data.each do |article_data|
      # instantiate a new ArticleHandler to process the article data
      article = ArticleHandler.new(article_data)

      # get last commit with a change on that article
      commits = @client.commits(@repo_id, MAIN_BRANCH, path: article.path)
      last_commit_date = commits.first[:commit][:committer][:date].to_date

      if last_commit_date == @expiration_date
        puts "#{article.path} is outdated"

        next if branch_exists_in_repo?(article.branch_name)

        puts "creating branch, pull request and issue"
        create_branch(article.branch_name)
        update_article_and_commit(article)
        create_pull_request(article)
        create_issue(article)
      end
    end
  end

  def branch_exists_in_repo?(branch_name)
    branches = @client.refs(@repo_id, nil, per_page: 100).map(&:ref)
    branch = "refs/heads/#{branch_name}"
    branches.include?(branch)
  end

  def create_branch(branch_name)
    puts 'Creating Branch'

    last_commit_on_master = @client.commits(@repo_id, MAIN_BRANCH).first

    @client.create_ref(
      @repo_id,
      "heads/#{branch_name}",
      last_commit_on_master[:sha]
    )
  end

  def update_article_and_commit(article)
    puts 'Pushing commit'

    @client.update_contents(
      @repo_id,
      article.path,
      'Unpublish outdated article',
      article.sha,
      article.unpublished_body,
      branch: article.branch_name)
  end

  def create_pull_request(article)
    puts 'Creating Pull Request'

    @client.create_pull_request(
      @repo_id,
      MAIN_BRANCH,
      article.branch_name,
      pull_request_title,
      pull_request_body(article)
    )
  end

  def pull_request_title
    'Unpublish outdated article'
  end

  def pull_request_body(article)
    "This PR unpublishes the article `#{article.path}` because " +
    "its last update was more than #{OUTDATED_MONTHS} months ago."
  end

  def create_issue(article)
    puts 'Creating Issue'

    begin
      @client.create_issue(
        @repo_id,
        issue_title(article),
        issue_body(article)
      )
    rescue Octokit::ClientError => error
      # Issues can be disabled in the repository settings so this can fail.
      puts error
    end
  end

  def issue_title(article)
    "#{article.path} needs to be updated"
  end

  def issue_body(article)
    "`#{article.path}` has been marked as unpublished and needs to be updated"
  end
end
