watcher = require "./watcher.js"
compile = require "./compiler.js"
tinylr = require "tiny-lr"
cltags = require "cltags"
http = require "http"
net = require "net"
tags = cltags.parse(process.argv, {ignore: false}, { h: "help", v: "version", V: "version" });

jjson = require '../package.json'
app_version = "jeet-npm v" + jjson.version

#Remove Extra Debug strings from Tiny-LR
clog = console.log
console.log = (object) ->
    if object.toString().substr(0, 10) isnt "... Reload"
        clog(object)

isPortTaken = (PORT, callback) ->
    tester = net.createServer()
    tester.once 'error', (err) ->
        if err.code is 'EADDRINUSE'
            callback(null, true)
        else
            callback(err)
    tester.once 'listening', () ->
        tester.once 'close', () ->
            callback(null, false)
        tester.close()
    tester.listen(PORT)

startLiveReload = () ->
    isPortTaken 35729, (err, taken) ->
        if not err and not taken
            tinylr().listen 35729, () ->
            tags.livereload = true
            console.log "Live Reload is listening on port 35729"
        else if not err and taken
            tags.livereload = false
            console.log "\x1B[0;31mThe livereload port seems to be in use by another app, so live-reload will be turned off\x1B[0;0m"
        else
            console.log "\x1B[0;31m" + err + "\x1B[0;0m\n"
            process.kill()

if tags.command is "watch"
    startLiveReload()
    watcher.watch (file) ->
        if file.substr(-5) is ".styl"
            compile(watcher.stylFile);
        else if tags.livereload
            http.get "http://localhost:35729/changed?files=" + file
            console.log "\x1B[0;32m" + file.split("/").pop() + " modified & reloaded\x1B[0;0m"
        else
            console.log "\x1B[0;32m" + file.split("/").pop() + " modified\x1B[0;0m"


else if tags.command is "create" or tags.create is true
    if not tags.ignore
        ajson = require "../node_modules/axis-css/package.json"
        sjson = require "../node_modules/stylus/package.json"
        check = [jjson, ajson, sjson]
        npm = "http://registry.npmjs.org/"

        (lookup = () ->
            if check.length is 0
                #create
            else
                p = check.shift()
                http.get(npm + p.name + "/latest", (res) ->
                    data = ""
                    res.on "data", (d) ->
                        data += d.toString()
                    res.on "end", () ->
                        data = JSON.parse(data);
                        if data.version isnt p.version
                            console.log "There is a newer version of " + p.name + " available please run `\x1B[0;1mnpm install -g jeet\x1B[0;0m` before creating a new project"
                        else
                            lookup()
                ).on 'error', (e) ->
                    lookup()
        )()
    else
        #create


else if tags.command is "help" or tags.help is true
    console.log """
    Usage: jeet [options] [command]

    Commands:
        watch                   watch the current path and recompile CSS on changes

        Options:
            -h, --help          output usage information
            -V/-v, --version    output the version number

                """

else if tags.command is "version" or tags.version is true
    console.log app_version


