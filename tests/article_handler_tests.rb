require_relative '../models/article_handler.rb'

describe ArticleHandler do
  before do
    @article_data = {
      name: "2017-08-22-some-old-blogpost.md",
      path: "_posts/2017-08-22-some-old-blogpost.md",
      sha: "36dd0659c57733f6c8ad34f65792b04",
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
