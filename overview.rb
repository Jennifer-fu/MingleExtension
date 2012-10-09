require "rexml/document"
require "open-uri"
require "net/http"

module OverviewScript
  extend self

  MingleServerAndPort = '163.184.134.16:8080'
  MingleUserName = 'admin'
  MinglePassword = '123456'

  TemplateNames = ['Display_Team_Sprint_Overview', 'Data1_Team_Sprint_Overview',
                  'Data2_Team_Sprint_Overview', 'Performance_Team_Sprint_Overview',
                  'Workflow_DM_Team_Sprint_Overview', 'Workflow_WL_Team_Sprint_Overview',
                  'Environment_CI_Team_Sprint_Overview']

  MaxWellURI = 'api/v2/projects/mingleapitest'
  URLForAddingWiki = "http://#{MingleUserName}:#{MinglePassword}@#{MingleServerAndPort}/#{MaxWellURI}/wiki.xml"

  def generateOverviews

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

    TemplateNames.each { |templateName|
      urlForGettingTemplate = "http://#{MingleServerAndPort}/#{MaxWellURI}/wiki/#{templateName}.xml"

      open(urlForGettingTemplate, :http_basic_authentication => [MingleUserName, MinglePassword]) do |f|
        templatePage = REXML::Document.new(f)
        templateContent = replaceTagsWithValues(templatePage.elements['page/content'].text, tagsAndValues)

        Net::HTTP.post_form(URI.parse(URLForAddingWiki),
                            {'page[name]' => wikiPageName(templateName, tagsAndValues),
                             'page[content]' => templateContent})
      end
    }
  end

end

OverviewScript.generateOverviews

