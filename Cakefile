fs        = require 'fs'
path      = require 'path'
childProc = require 'child_process'

option('-v', '--verbose', 'verbose output')

extendGlobalWith = (obj) ->
    for key, val of obj
        global[key] = val

checkAndRemoveFile = (filepath) ->
    if path.existsSync(filepath)
        return fs.unlinkSync(filepath)

task 'test', 'run the full spec test suite', (options) ->
    verbose = options.verbose and true or false
    colored = true

    try
        jasmine = require './dev/third_party/jasmine-node/lib/jasmine-node'
    catch requireError
        console.log 'missing a development testing dependency:'
        process.stderr.write "#{ JSON.stringify requireError }\n"
        process.exit 1

    extendGlobalWith jasmine

    specPath = path.join __dirname, 'dev', 'spec'

    afterSpecRun = (runner, log) ->
        failures = runner.results().failedCount
        if failures then process.exit 1 else process.exit 0

    pattern = new RegExp "spec\.coffee$", "i"
    jasmine.executeSpecsInFolder specPath, afterSpecRun, verbose, colored, pattern

task 'update', 'update the project repository', ->
    checkAndRemoveFile './bin/cake'
    checkAndRemoveFile './bin/coffee'
    checkAndRemoveFile './bin/nave'
    childProc.exec 'bin/init', (err, stdout, stderr) ->
        if err
            return process.stderr.write err.toString()

        if stdout
            return console.log stdout

        if stderr
            return process.stderr.write stderr.toString()

