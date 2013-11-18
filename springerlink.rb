#!/usr/bin/env ruby
#UTF-8 encoding

require 'nokogiri'
require 'open-uri'

class Springerlink
  def initialize(journal_id)
    page_numbers = get_total_page_number(journal_id)
    page_numbers.times do |page_no|
      doc = get_document(journal_id, page_no+1)
      article_hash = get_article_hash(doc)
      download_articles(article_hash, doc)
    end
  #rescue
    #puts "\nNo journal ID specified.\n\nExample: springerlink.rb 11576"
  end

  def get_total_page_number(journal_id)
    get_document(journal_id, 1).css('span.number-of-pages').first.text.to_i
  end

  def get_document(journal_id, page_number)
    Nokogiri::HTML(open("http://link.springer.com/search/page/#{page_number}?facet-journal-id=#{journal_id}&sortOrder=newestFirst&facet-content-type=Article"))
  end

  def get_article_hash(document)
    published_dates = document.css('span.year')
    download_links = []
    document.css('a.pdf-link').map { |link| download_links << "http://link.springer.com" + link['href'] }
    article_hash = {}
    document.css('a.title').map.with_index { |article,i| article_hash[download_links[i]] = article.text.gsub(/[\x00\/\\:\*\?\"<>\|„“]/, '') }
    article_hash.keys.map.with_index { |article,i| article_hash[article] = [ published_dates[i].attributes["title"].value.split.reverse, article_hash.delete(article) ] }
    article_hash
  end

  def download_articles(article_hash, document)
    article_hash.each do |link|
      journal = document.css('img.cover').first.attributes["alt"].value
      download_link = link[0][0]
      title = link[1][1]
      year = link[1][0][0]
      month = Date::MONTHNAMES.index(link[1][0][1])
      `mkdir -p #{journal}/#{year}/#{month}`
      `wget #{download_link} -O '#{journal}/#{year}/#{month}/#{title}.pdf'`
    end
  end
end

Springerlink.new(ARGV[0])
