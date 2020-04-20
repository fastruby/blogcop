require 'httparty'

class ArticleHandler
  def initialize(article_data)
    @data = article_data
  end

  def path
    @data[:path]
  end

  def sha
    @data[:sha]
  end

  def branch_name
    "unpublish/#{@data[:name]}"
  end

  def unpublished_body
    body.gsub(header, unpublished_header)
  end

  def body
    HTTParty.get(@data[:download_url]).body
  end

  def header
    body[/#{'---'}(.*?)#{'---'}/m, 1]
  end

  def unpublished_header
    headers_attributes = header.split("\n")
    unpublished = 'published: false'

    headers_attributes.map! do |attribute|
      attribute.include?('published:') ? unpublished : attribute
    end

    unless headers_attributes.include?(unpublished)
      headers_attributes << unpublished
    end

    headers_attributes.join("\n") + "\n"
  end
end
