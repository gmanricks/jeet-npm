uglify = require "uglify-js"
fs = require "fs"

#By Chrisopher Jeffrey
getFiles = (dir, done) ->
    results = []
    fs.readdir dir, (err, list) ->
        return done(err) if err
        i = 0
        (next = () ->
            file = list[i++];
            return done(null, results) if not file
            if file.charAt(0) is "." or file is "minified.js" or file.substr(0, 6) is "jquery" or file.substr(0, 9) is "modernizr" or file.substr(0, 11) is "selectivizr"
                next()
            else
                file = dir + '/' + file
                fs.stat file, (err, stat) ->
                    if stat and stat.isDirectory()
                        getFiles file, (err, res) ->
                            results = results.concat(res)
                            next()
                    else
                        if file.substr(-3) is ".js"
                            results.push file
                        next()
        )();

exports = module.exports = (path) ->
    getFiles path, (err, files) ->
        data = uglify.minify(files)
        fs.writeFileSync path + "/minified.js", data.code
        console.log "Recompiled JS into minified.js"
