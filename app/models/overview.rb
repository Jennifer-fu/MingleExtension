require "rexml/document"
require "open-uri"
require "net/http"
require "mingleAPIHelper"

class Overview
  include MingleAPIHelper
  
  attr_accessor :sprint_order
  attr_accessor :sprint_start_date
  attr_accessor :sprint_end_date
  attr_accessor :release_order

  TemplateNames = ['Display_Team_Sprint_Overview', 'Data1_Team_Sprint_Overview',
                  'Data2_Team_Sprint_Overview', 'Performance_Team_Sprint_Overview',
                  'Workflow_DM_Team_Sprint_Overview', 'Workflow_WL_Team_Sprint_Overview',
                  'Environment_CI_Team_Sprint_Overview']

  MaxWellURI = '/api/v2/projects/mingleapitest'

  def generateOverviews
    generateOverviewsAccordingToTemplates
    updateOverviewList
  end

  def generateOverviewsAccordingToTemplates

    def replaceTagsWithValues(content, tagsAndValues)
      tagsAndValues.to_a.inject(content) { |content, tagAndValue| content.gsub(tagAndValue[0], tagAndValue[1]) }
    end

    def wikiPageName(prefix, tagsAndValues)
      prefix + ' - ' + tagsAndValues[%r{\(Current Sprint\)}][1..-2]
    end

    scriptTemplatesURI = "/api/v2/projects/mingle_script_templates"

    tagsAndValues = {
        %r{\(Current Sprint Order\)} => %Q{"#{sprint_order}"},
        %r{\(Current Sprint\)} => %Q{"Sprint #{sprint_order}"},
        %r{\(Current Sprint Start Date\)} => %Q{"#{sprint_start_date}"},
        %r{\(Current Sprint End Date\)} => %Q{"#{sprint_end_date}"},
        %r{\(Current Release\)} => %Q{"Release #{release_order}"}
    }

    TemplateNames.each { |templateName|
      text = askMingle("#{scriptTemplatesURI}/wiki/#{templateName}.xml", %q{//page/content}).first
      putToMingle("#{MaxWellURI}/wiki.xml",
                  {'page[name]' => wikiPageName(templateName, tagsAndValues),
                  'page[content]' => replaceTagsWithValues(text, tagsAndValues)})
    }
  end

  def updateOverviewList

    def findHowManySprintOverviewsAlreadyInTheProject
      askMingle("#{MaxWellURI}/wiki.xml", %q{//page[contains(name, ' - Sprint')]/name}).inject([]) { |numbers, text|
        numbers << text[/\s-\sSprint\s([0-9]+)$/, 1]
      }.uniq
    end

    def generateContentOfSprintOverviewList(teamName, sprintNumbers)
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

    def getTeamName(templateName)
      templateName[/(\w+)_Sprint_Overview/, 1].gsub(/_/, ' ')
    end

    def updateOverview(templateName, content)
      putToMingle("#{MaxWellURI}/wiki/#{templateName}.xml", "page[content]=#{content}")
    end

    TemplateNames.each do |templateName|
      sprintNumbers = findHowManySprintOverviewsAlreadyInTheProject
      overviewContent = generateContentOfSprintOverviewList(getTeamName(templateName), sprintNumbers)
      updateOverview(templateName, overviewContent)
    end
  end
end