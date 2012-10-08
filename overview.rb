require "rexml/document"
require "open-uri"
require "net/http"

MingleServerAndPort = '163.184.134.16:8080'
MingleUserName = 'admin'
MinglePassword = '123456'

TemplateName = 'Display_Team_Sprint_Overview'
MaxWellURI = 'api/v2/projects/maxwell'
URLForGettingTemplate = "http://#{MingleServerAndPort}/#{MaxWellURI}/wiki/#{TemplateName}.xml"
URLForAddingWiki = "http://#{MingleUserName}:#{MinglePassword}@#{MingleServerAndPort}/#{MaxWellURI}/wiki.xml"

WikiPageName = 'test wiki page'

tagsAndValues = {
    %r{\(Current Sprint Order\)} => %q{'3'},
    %r{\(Current Sprint\)} => %q{'Sprint 3'},
    %r{\(Current Sprint Start Date\)} => %q{'2012-09-20'},
    %r{\(Current Sprint End Date\)} => %q{'2012-10-01'},
    %r{\(Current Release\)} => %q{'Release 1'}
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

