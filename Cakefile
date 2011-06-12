fs           = require 'fs'
path         = require 'path'
childProcess = require 'child_process'

verbose = false

spawn = childProcess.spawn

option('-v', '--verbose', 'verbose output')

setOptions = (opts) ->
    verbose = opts.verbose

log = (args...) ->
    if not verbose then return
    return console.log(args.join(' '))

exec = (bin, args, callback) ->
    if verbose then console.log("  #{ bin } #{ args }")
    proc = spawn(bin, args)
    proc.stdout.on 'data', (buffer) ->
        if verbose then process.stdout.write("    #{ buffer.toString() }")
    proc.stderr.on 'data', (buffer) ->
        if verbose then process.stderr.write("    #{ buffer.toString() }")
    proc.on 'exit', (status) -> callback(status)
    return

brewCoffee = (args, callback) -> exec('coffee', args, callback)

brewDirectory = (dirname, callback) ->
    files = fs.readdirSync(dirname)
    files = (dirname + file for file in files when file.match(/\.coffee$/))
    return brewCoffee(['-c', '-b', '-o', dirname].concat(files), callback)

extendGlobalWith = (obj) ->
    for key, val of obj
        global[key] = val

checkAndRemoveFile = (filepath) ->
    if path.existsSync(filepath)
        return fs.unlinkSync(filepath)


task 'test', 'run the full spec test suite', (options) ->
    setOptions(options)
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

    pattern = new RegExp('spec\.coffee$', 'i')
    jasmine.executeSpecsInFolder(specPath, afterSpecRun, verbose, colored, pattern)
    return


task 'update', 'update the project repository', ->
    checkAndRemoveFile './bin/cake'
    checkAndRemoveFile './bin/coffee'
    checkAndRemoveFile './bin/nave'
    childProcess.exec 'bin/init', (err, stdout, stderr) ->
        if err
            return process.stderr.write err.toString()

        if stdout
            return console.log stdout

        if stderr
            return process.stderr.write stderr.toString()

        return
    return


task 'build', 'build the Alpinist', (options) ->
    setOptions(options)
    directories = [
        './'
        './lib/'
        './lib/third_party/stack/'
    ]

    len = directories.length
    count = 0

    onCoffeeBuild = (status) ->
        count += 1
        if status
            console.log('not ok')
            console.log('! Problem building CoffeeScript ^^^')
            if not verbose
                console.log(' use the verbosity switch -v to see more')
            process.exit(status)

        if count is len
            console.log('ok: build done')

    brewDirectory(dir, onCoffeeBuild) for dir in directories
    return
