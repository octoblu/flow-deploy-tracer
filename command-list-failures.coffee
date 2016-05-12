_         = require 'lodash'
colors    = require 'colors'
moment    = require 'moment'
commander = require 'commander'
tab = require 'tab'
Elasticsearch = require 'elasticsearch'
debug     = require('debug')('command-trace:check')
QUERY = require './get-failed-deployments.json'

class CommandTrace
  parseOptions: =>
    commander
      .option '-o, --omit-header', 'Omit meta-information and table header'
      .option '-i, --in-last [time unit]',     'Show failures sinse some value i.e. 1d or 30minutes'
      .parse process.argv

    @ELASTICSEARCH_URL = process.env.ELASTICSEARCH_URL ? 'http://localhost:9201'
    @elasticsearch = new Elasticsearch.Client host: @ELASTICSEARCH_URL

    @omitHeader = commander.omitHeader ? false
    @inLast = commander.inLast ? '1d'

  run: =>
    @parseOptions()
    @listFailures()

  listFailures: =>
    @search (error, results) =>
      return @die error if error?
      logs = results.hits.hits

      @printTable _.map logs, (log) =>
        {beginTime, workflow, deploymentUuid} = log._source
        timestamp = moment(beginTime).toISOString()
        [timestamp, workflow, deploymentUuid]

      process.exit 0

  printTable: (rows) =>
    tab.emitTable
      omitHeader: @omitHeader
      columns: [
        {label: 'TIME', width: 28},
        {label: 'WORKFLOW', width: 10}
        {label: 'DEPLOYMENT_UUID', width: 34}
      ]
      rows: rows

  search: (callback=->) =>
    @elasticsearch.search({
      index: 'flow_deploy_history'
      type:  'event'
      body:  @query()
    }, callback)

  query: =>
    query = _.cloneDeep QUERY
    query.query.filtered.filter.and.push range: beginTime: gte: "now-#{@inLast}"
    query

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new CommandTrace().run()
