require "rexml/document"
require "open-uri"
require "net/http"

module OverviewScript
  extend self

  MingleServer = '163.184.134.16'
  MingleServerPort = '8080'
  MingleServerAndPort = "#{MingleServer}:#{MingleServerPort}"
  MingleUserName = 'admin'
  MinglePassword = '123456'

  TemplateNames = ['Display_Team_Sprint_Overview', 'Data1_Team_Sprint_Overview',
                  'Data2_Team_Sprint_Overview', 'Performance_Team_Sprint_Overview',
                  'Workflow_DM_Team_Sprint_Overview', 'Workflow_WL_Team_Sprint_Overview',
                  'Environment_CI_Team_Sprint_Overview']

  MaxWellURI = '/api/v2/projects/mingleapitest'

  def generateOverviews releaseOrder, sprintOrder, sprintStartDate, sprintEndDate

    scriptTemplatesURI = "/api/v2/projects/mingle_script_templates"
    urlForAddingWiki = "http://#{MingleUserName}:#{MinglePassword}@#{MingleServerAndPort}#{MaxWellURI}/wiki.xml"

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
      prefix + ' - ' + tagsAndValues[%r{\(Current Sprint\)}][1..-2]
    end

    TemplateNames.each { |templateName|
      urlForGettingTemplate = "http://#{MingleServerAndPort}#{scriptTemplatesURI}/wiki/#{templateName}.xml"

      open(urlForGettingTemplate, :http_basic_authentication => [MingleUserName, MinglePassword]) do |f|
        templatePage = REXML::Document.new(f)
        templateContent = replaceTagsWithValues(templatePage.elements['page/content'].text, tagsAndValues)

        Net::HTTP.post_form(URI.parse(urlForAddingWiki),
                            {'page[name]' => wikiPageName(templateName, tagsAndValues),
                             'page[content]' => templateContent})
      end
    }
  end

  def requestAPI apiURI, xpath
    Enumerator.new do |y|
      open("http://#{MingleServerAndPort}#{apiURI}", :http_basic_authentication => [MingleUserName, MinglePassword]) do |f|
        REXML::Document.new(f).each_element(xpath) do |e|
          y << e.text
        end
      end
    end
  end

  def findHowManySprintOverviewsAlreadyInTheProject
    requestAPI("#{MaxWellURI}/wiki.xml", %q{//page[contains(name, ' - Sprint')]/name}).inject([]) { |numbers, text|
      numbers << text[/\s-\sSprint\s([0-9]+)$/, 1]
    }.uniq
  end

  def generateContentOfSprintOverviewList teamName, sprintNumbers
    header = <<-HEADER
        {% dashboard-panel %}
        {% panel-heading %}#{teamName} Sprint Overview{% panel-heading %}
        {% panel-content %}
    HEADER

    footer = <<-FOOTER
        {% panel-content %}
        {% dashboard-panel %}
    FOOTER

    sprintNumbers.inject(header) { |content, number|
      content << "[[#{teamName} Sprint Overview - Sprint #{number}]]<br/>\n"
    } << footer
  end

  def getTeamName templateName
    templateName[/(\w+)_Sprint_Overview/, 1].gsub(/_/, ' ')
  end

  def updateOverview templateName, content
    uriOfOverviewList = "#{MaxWellURI}/wiki/#{templateName}.xml"

    putRequest = Net::HTTP::Put.new(uriOfOverviewList)
    putRequest.basic_auth MingleUserName, MinglePassword
    putRequest.body = "page[content]=#{content}"

    Net::HTTP.new(MingleServer, MingleServerPort).start { |http| http.request(putRequest) }
  end

  def updateOverviewList
    TemplateNames.each { |templateName|
      sprintNumbers = findHowManySprintOverviewsAlreadyInTheProject
      overviewContent = generateContentOfSprintOverviewList(getTeamName(templateName), sprintNumbers)
      updateOverview(templateName, overviewContent)
    }
  end

end

#OverviewScript.generateOverviews ARGV[0], ARGV[1], ARGV[2], ARGV[3]

