require "rexml/document"
require "open-uri"
require "net/http"

MingleServerAndPort = '163.184.134.16:8080'
MingleUserName = 'admin'
MinglePassword = '123456'

TemplateName = 'Display_Team_Sprint_Overview'
MaxWellURI = 'api/v2/projects/mingleapitest'
URLForGettingTemplate = "http://#{MingleServerAndPort}/#{MaxWellURI}/wiki/#{TemplateName}.xml"
URLForAddingWiki = "http://#{MingleUserName}:#{MinglePassword}@#{MingleServerAndPort}/#{MaxWellURI}/wiki.xml"

WikiPageName = 'test wiki page'

ARGV.each do |a|
  puts "#{a}"
end

tagsAndValues = {
    %r{\(Current Sprint Order\)} => %Q{"#{ARGV[0]}"},
    %r{\(Current Sprint\)} => %Q{"#{ARGV[1]}"},
    %r{\(Current Sprint Start Date\)} => %Q{"#{ARGV[2]}"},
    %r{\(Current Sprint End Date\)} => %Q{"#{ARGV[3]}"},
    %r{\(Current Release\)} => %Q{"#{ARGV[4]}"}
}

def replaceTagsWithValues content, tagsAndValues
  tagsAndValues.to_a.inject(content) { |content, tagAndValue| content.gsub(tagAndValue[0], tagAndValue[1]) }
end

def wikiPageName prefix, tagsAndValues
  prefix + ' | ' + tagsAndValues[%r{\(Current Sprint\)}][1..-2]
end


open(URLForGettingTemplate, :http_basic_authentication => [MingleUserName, MinglePassword]) do |f|
  templatePage = REXML::Document.new(f)
  templateContent = replaceTagsWithValues(templatePage.elements['page/content'].text, tagsAndValues)

  Net::HTTP.post_form(URI.parse(URLForAddingWiki),
                      {'page[name]' => wikiPageName(TemplateName, tagsAndValues), 'page[content]' => templateContent})
end

