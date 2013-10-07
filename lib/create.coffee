fs = require "fs"
https = require "https"
ghd = require "./githubd.js"
path = require "path"

#By Chrisopher Jeffrey
getFiles = (dir, done) ->
    results = []
    fs.readdir dir, (err, list) ->
        return done(err) if err
        i = 0
        (next = () ->
            file = list[i++];
            return done(null, results) if not file
            if file.charAt(0) is "."
                next()
            else
                file = dir + path.sep + file
                fs.stat file, (err, stat) ->
                    if stat and stat.isDirectory()
                        getFiles file, (err, res) ->
                            results = results.concat(res)
                            next()
                    else
                        results.push file
                        next()
        )();



#Helper to create directories recursively
mkdirp = (lp, fpath) ->
    fpath = fpath.split(path.sep)
    cp = lp if typeof lp is "string"
    cp = path.normalize(cp + path.sep)
    for p in fpath
        cp += p + path.sep
        if not fs.existsSync cp
            fs.mkdirSync cp

cloneLocalRepo = (foldername, name) ->
        ignore = ["README.md", "watch", "bower.json", "package.json"]
        localpath = path.normalize(process.cwd() + path.sep + name + path.sep)
        if name is "." or name is "./"
            localpath = path.normalize(process.cwd() + path.sep)
            name = process.cwd().split(path.sep).pop()

            if fs.existsSync localpath + "css" + path.sep + "jeet" + path.sep
                console.log "this is already a Jeet project"
                process.kill();
        else
            if fs.existsSync localpath
                console.log name + " already exists"
                process.kill();
            else
                fs.mkdirSync(localpath)
        getFiles foldername, (err, files) ->
            (cycle = ()->
                if files.length is 0
                    console.log "Created project \x1B[0;1m" + name + "\x1B[0;0m"
                else
                    file = files.shift()
                    rfile = file.substr(foldername.length + 1)
                    if ignore.indexOf(rfile) is -1
                        fpath = rfile.split(path.sep)
                        rfile = fpath.pop()
                        fpath = fpath.join(path.sep)
                        mkdirp(localpath, fpath)
                        ws = fs.createWriteStream(path.normalize(localpath + path.sep + fpath + path.sep + rfile));
                        fs.createReadStream(file).pipe(ws);
                        ws.on "close", () ->
                            cycle()
                    else
                        cycle()
            )()


exports = module.exports = (name, ignore, debug) ->
    if debug
        console.log "Dirname: " + __dirname
    foldername = path.normalize(__dirname + path.sep + ".." + path.sep + "jeet" + path.sep)
    if not ignore
        ghd.updateByRepo "CorySimmons", "jeet", foldername, (err) ->
            if err
                console.log(err)
            else
                cloneLocalRepo foldername, name
    else
        cloneLocalRepo foldername, name

