require_relative './article_handler.rb'
require_relative './repository_handler.rb'
require "minitest/autorun"

describe ArticleHandler do
  before do
    @article_data = {
      :name => "2017-08-22-how-we-helped-predictable-revenue-scale.md",
      :path => "_posts/2017-08-22-how-we-helped-predictable-revenue-scale.md",
      :sha => "36dd0659c57733f6c8ad34f65792b040a58d0445",
      :size => 7196,
      :url => "https://api.github.com/repos/ombulabs/blog/contents/_posts/2017-08-22-how-we-helped-predictable-revenue-scale.md?ref=master",
      :html_url => "https://github.com/ombulabs/blog/blob/master/_posts/2017-08-22-how-we-helped-predictable-revenue-scale.md",
      :git_url => "https://api.github.com/repos/ombulabs/blog/git/blobs/36dd0659c57733f6c8ad34f65792b040a58d0445",
      :download_url => "https://raw.githubusercontent.com/ombulabs/blog/master/_posts/2017-08-22-how-we-helped-predictable-revenue-scale.md",
      :type => "file",
      :_links => {
        :self => "https://api.github.com/repos/ombulabs/blog/contents/_posts/2017-08-22-how-we-helped-predictable-revenue-scale.md?ref=master",
        :git => "https://api.github.com/repos/ombulabs/blog/git/blobs/36dd0659c57733f6c8ad34f65792b040a58d0445",
        :html => "https://github.com/ombulabs/blog/blob/master/_posts/2017-08-22-how-we-helped-predictable-revenue-scale.md"
      }
    }
    @article = ArticleHandler.new(@article_data)

    @article_body = <<-BODY
---
layout: post
title: "4 Useful Github tricks which should be more popular"
date: 2015-01-19 18:35:00
reviewed: 2020-03-05 10:00:00
categories: ["git", "github"]
author: "mauro-oto"
---

If you are using git in 2015, you are probably also using [Github](http://www.github.com), unless you're self-hosting or still betting on [Bitbucket](http://www.bitbucket.com).

Below are some cool, useful tricks you can use on Github which can probably make your life easier:

<!--more-->

## T

This is probably the most-well known and most used. By hitting the T key while browsing a repository, the file finder comes up, which lets you type in any file and it will search for that filename in the repository.

You can also navigate using the arrow keys, and access the file by hitting Enter.

## .diff / .patch

By appending .diff to any diff URL on Github, you'll be able to see the plain-text version of it, as if looking at output from git.

## ?w=1

A not-so-well-known tip is appending ?w=1 to a diff URL to omit whitespaces from a diff.

[Example diff on ombulabs/setup](https://github.com/ombulabs/setup/commit/7c824aaca37a401bdd6d0f8acd1b11f510648bb4) vs [Example diff on ombulabs/setup with w=1](https://github.com/ombulabs/setup/commit/7c824aaca37a401bdd6d0f8acd1b11f510648bb4?w=1)

Probably not the best example but useful to remember for longer diffs.

## .keys

You can get anyone's public keys by appending .keys to their Github username. For instance, to get my public keys: [mauro-oto](https://github.com/mauro-oto.keys)

For great git-specific tips, try [here](http://mislav.uniqpath.com/2010/07/git-tips/) or [here](http://gitready.com/).
BODY
  end

  describe '.header' do
    it 'returns only the header of the post' do
      # stub body method to prevent the http request
      header = <<-HEADER

layout: post
title: "4 Useful Github tricks which should be more popular"
date: 2015-01-19 18:35:00
reviewed: 2020-03-05 10:00:00
categories: ["git", "github"]
author: "mauro-oto"
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
title: "4 Useful Github tricks which should be more popular"
date: 2015-01-19 18:35:00
reviewed: 2020-03-05 10:00:00
categories: ["git", "github"]
author: "mauro-oto"
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
title: "4 Useful Github tricks which should be more popular"
date: 2015-01-19 18:35:00
reviewed: 2020-03-05 10:00:00
categories: ["git", "github"]
author: "mauro-oto"
published: false
---

If you are using git in 2015, you are probably also using [Github](http://www.github.com), unless you're self-hosting or still betting on [Bitbucket](http://www.bitbucket.com).

Below are some cool, useful tricks you can use on Github which can probably make your life easier:

<!--more-->

## T

This is probably the most-well known and most used. By hitting the T key while browsing a repository, the file finder comes up, which lets you type in any file and it will search for that filename in the repository.

You can also navigate using the arrow keys, and access the file by hitting Enter.

## .diff / .patch

By appending .diff to any diff URL on Github, you'll be able to see the plain-text version of it, as if looking at output from git.

## ?w=1

A not-so-well-known tip is appending ?w=1 to a diff URL to omit whitespaces from a diff.

[Example diff on ombulabs/setup](https://github.com/ombulabs/setup/commit/7c824aaca37a401bdd6d0f8acd1b11f510648bb4) vs [Example diff on ombulabs/setup with w=1](https://github.com/ombulabs/setup/commit/7c824aaca37a401bdd6d0f8acd1b11f510648bb4?w=1)

Probably not the best example but useful to remember for longer diffs.

## .keys

You can get anyone's public keys by appending .keys to their Github username. For instance, to get my public keys: [mauro-oto](https://github.com/mauro-oto.keys)

For great git-specific tips, try [here](http://mislav.uniqpath.com/2010/07/git-tips/) or [here](http://gitready.com/).
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