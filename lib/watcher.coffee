fs = require "fs"
exports = module.exports = {}

locateRoot = (root) ->
    return root if fs.existsSync root + "/css/jeet.styl"
    if fs.existsSync root + "/jeet.styl"
        root = root.split "/"
        return root.slice(0, root.length - 1).join "/"
    else if fs.existsSync root + "/jeet/css/jeet.styl"
        return root + "/jeet";
    else
        return false


#By Chrisopher Jeffrey
getFiles = (dir, done) ->
    results = {}
    fs.readdir dir, (err, list) ->
        return done(err) if err
        i = 0
        (next = () ->
            file = list[i++];
            return done(null, results) if not file
            if file.charAt(0) is "."
                next()
            else
                file = dir + '/' + file
                fs.stat file, (err, stat) ->
                    if stat and stat.isDirectory()
                        getFiles file, (err, res) ->
                            for f, v of res
                                results[f] = v
                            next()
                    else
                        results[file] = stat
                        next()
        )();

cycle = (path, list, cb) ->
    getFiles path, (err, files) ->
        for f, s of files
            if not list.hasOwnProperty(f)
                cb f
            else if list[f].size isnt s.size or list[f].mtime.getTime() isnt s.mtime.getTime()
                cb f
        setTimeout(() ->
            cycle(path, files, cb)
        , 100)

exports.watch = (cb) ->
    root = locateRoot process.cwd()
    exports.stylFile = root + "/css/"
    if root
        getFiles root, (err, files) ->
            cycle(root, files, cb)
    else
        console.log "Doesn't appear to be a Jeet Directory"
