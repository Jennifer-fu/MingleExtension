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
  ScriptTemplatesURI = "api/v2/projects/mingle_script_templates"
  URLForAddingWiki = "http://#{MingleUserName}:#{MinglePassword}@#{MingleServerAndPort}/#{MaxWellURI}/wiki.xml"

  def generateOverviews releaseOrder, sprintOrder, sprintStartDate, sprintEndDate

    tagsAndValues = {
        %r{\(Current Sprint Order\)} => %Q{"#{sprintOrder}"},
        %r{\(Current Sprint\)} => %Q{"Sprint #{sprintOrder}"},
        %r{\(Current Sprint Start Date\)} => %Q{"#{sprintStartDate}"},
        %r{\(Current Sprint End Date\)} => %Q{"#{sprintEndDate}"},
        %r{\(Current Release\)} => %Q{"Release #{releaseOrder}"}
    }

    def replaceTagsWithValues content, tagsAndValues
      tagsAndValues.to_a.inject(content) { |content, tagAndValue| content.gsub(tagAndValue[0], tagAndValue[1]) }
    end

    def wikiPageName prefix, tagsAndValues
      prefix + ' | ' + tagsAndValues[%r{\(Current Sprint\)}][1..-2]
    end

    TemplateNames.each { |templateName|
      urlForGettingTemplate = "http://#{MingleServerAndPort}/#{ScriptTemplatesURI}/wiki/#{templateName}.xml"

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

OverviewScript.generateOverviews ARGV[0], ARGV[1], ARGV[2], ARGV[3]

