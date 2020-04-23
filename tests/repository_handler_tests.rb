require_relative '../models/repository_handler.rb'

describe RepositoryHandler do
  before do
    article_data = {path: 'some_path'}
    @article = ArticleHandler.new(article_data)
    @repo = RepositoryHandler.new(nil, nil)
  end

  describe '.pull_request_title' do
    it 'returns the expected title' do
      _(@repo.pull_request_title).must_equal 'Unpublish outdated article'
    end
  end

  describe '.pull_request_body' do
    it 'returns the expected body with the article title and the months' do
      body = "This PR unpublishes the article `some_path` because " +
      "its last update was more than 3 months ago."

      _(@repo.pull_request_body(@article)).must_equal body
    end
  end

  describe '.issue_title' do
    it 'returns the expected title with the article path' do
      title = 'some_path needs to be updated'
      _(@repo.issue_title(@article)).must_equal title
    end
  end

  describe '.issue_body' do
    it 'returns the expected body with the article path' do
      body = '`some_path` has been marked as unpublished and needs to be updated'
      _(@repo.issue_body(@article)).must_equal body
    end
  end
end
