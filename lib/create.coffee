fs = require "fs"
https = require "https"
ghd = require "./githubd.js"

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
                file = dir + '/' + file
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
mkdirp = (lp, path) ->
    path = path.split("/")
    cp = lp if typeof lp is "string"
    cp = cp + "/" if cp.charAt(cp.length-1) isnt "/"
    for p in path
        cp += p + "/"
        if not fs.existsSync cp
            fs.mkdirSync cp

cloneLocalRepo = (foldername, name) ->
        ignore = ["README.md", "watch", "bower.json", "package.json"]
        localpath = "./" + name + "/"
        if name is "." or name is "./"
            localpath = "./"
            name = process.cwd().split("/").pop()

        if localpath is "./"
            if fs.existsSync "./css/jeet/"
                console.log "this is already a Jeet project"
                process.kill();
        else if fs.existsSync localpath
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
                        path = rfile.split("/")
                        rfile = path.pop()
                        path = path.join("/")
                        mkdirp(localpath, path)
                        ws = fs.createWriteStream(localpath + path + "/" + rfile);
                        fs.createReadStream(file).pipe(ws);
                        ws.on "close", () ->
                            cycle()
                    else
                        cycle()
            )()


exports = module.exports = (name, ignore) ->
    foldername = __dirname.split("/")
    foldername = foldername.slice(0, foldername.length-1).join("/") + "/jeet"
    if not ignore
        ghd.updateByRepo "CorySimmons", "jeet", foldername, (err) ->
            if err
                console.log(err)
            else
                cloneLocalRepo foldername, name
    else
        cloneLocalRepo foldername, name

