watcher = require "./watcher.js"
compile = require "./compiler.js"
tinylr = require "tiny-lr"
cltags = require "cltags"
http = require "http"
net = require "net"
tags = cltags.parse(process.argv, {}, { h: "help", v: "version", V: "version" });

pjson = require '../package.json'
app_version = "jeet-npm v" + pjson.version

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
            console.log "\x1B[0;32mLive Reload is listening on port 35729\x1B[0;0m\n"
        else if not err and taken
            tags.livereload = false
            console.log "\x1B[0;31mThe livereload port seems to be in use by another app, so live-reload will be turned off\x1B[0;0m\n"
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


