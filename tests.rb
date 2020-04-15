require_relative './article_handler.rb'
require_relative './repository_handler.rb'
require "minitest/autorun"

describe ArticleHandler do
  before do
    @article_data = {
      :name => "2017-08-22-some-old-blogpost.md",
      :path => "_posts/2017-08-22-some-old-blogpost.md",
      :sha => "36dd0659c57733f6c8ad34f65792b04",
    }
    @article = ArticleHandler.new(@article_data)

    @article_body = <<-BODY
---
layout: post
title: "My blog post Title"
date: 2015-01-19 18:35:00
reviewed: 2020-03-05 10:00:00
categories: ["git", "github"]
author: "someone"
---

fake test body
BODY
  end

  describe '.header' do
    it 'returns only the header of the post' do
      # stub body method to prevent the http request
      header = <<-HEADER

layout: post
title: "My blog post Title"
date: 2015-01-19 18:35:00
reviewed: 2020-03-05 10:00:00
categories: ["git", "github"]
author: "someone"
HEADER
      @article.stub :body, @article_body do
        _(@article.header).must_equal header
      end
    end
  end

  describe '.unpublished_header' do
    it 'returns a modified header with published: false' do
      # stub body method to prevent the http request
      header = <<-HEADER

layout: post
title: "My blog post Title"
date: 2015-01-19 18:35:00
reviewed: 2020-03-05 10:00:00
categories: ["git", "github"]
author: "someone"
published: false
HEADER
      @article.stub :body, @article_body do
        _(@article.unpublished_header).must_equal header
      end
    end
  end

  describe '.unpublished_body' do
    it 'returns the body with the unpublished header' do
      body = <<-BODY
---
layout: post
title: "My blog post Title"
date: 2015-01-19 18:35:00
reviewed: 2020-03-05 10:00:00
categories: ["git", "github"]
author: "someone"
published: false
---

fake test body
BODY
      @article.stub :body, @article_body do
        _(@article.unpublished_body).must_equal body
      end
    end
  end

  describe '.path' do
    it 'returns path from data' do
      _(@article.path).must_equal @article_data[:path]
    end
  end

  describe '.sha' do
    it 'returns sha from data' do
      _(@article.sha).must_equal @article_data[:sha]
    end
  end

  describe '.branch_name' do
    it 'returns the expected string' do
      _(@article.branch_name).must_equal "unpublish/#{@article_data[:name]}"
    end
  end
end

describe RepositoryHandler do
  before do
    @article = ArticleHandler.new({path: 'some_path'})
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
