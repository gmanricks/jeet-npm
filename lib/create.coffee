fs = require "fs"
https = require "https"

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

httpsload = (url, cb) ->
    https.get(url, (res) ->
        data = ""
        res.on "data", (d) ->
            data += d.toString()
        res.on "end", () ->
            cb(false, data)
    ).on "error", () ->
        cb(true)

getGithubFiles = (url, done) ->
    ignore = ["README.md", "watch"]
    results = []
    httpsload url, (err, json) ->
        return done(true) if err
        list = JSON.parse(json)
        i = 0
        (next = () ->
            file = list[i++]
            return done(false, results) if not file
            if file.name.charAt(0) is "." or ignore.indexOf(file.name) isnt -1
                next()
            else
                if file.type is "dir"
                    getGithubFiles file.url, (err, res) ->
                        results = results.concat(res)
                        next()
                else
                    results.push file.url
                    next()
        )();

downloadGithubFiles = (foldername, files, cb) ->
    (cycle = () ->
        if files.length is 0
            cb(false)
        else
            file = files.shift()
            httpsload file, (err, json) ->
                cb(true) if err
                data = JSON.parse(json)
                contents = new Buffer(data.content, "base64").toString()
                fs.writeFile foldername + "/" + data.path, contents, (err) ->
                    cb(true) if err
                    cycle()
    )();

mkdirp = (lp, path) ->
    path = path.split("/")
    cp = lp
    for p in path
        cp += p + "/"
        if not fs.existsSync cp
            fs.mkdirSync(cp)

pullFromGithub = (foldername, cb) ->
    console.log "Downloading a newer version of jeet"
    getGithubFiles "https://api.github.com/repos/CorySimmons/jeet/contents/", (err, files) ->
        cb() if err
        downloadGithubFiles foldername, files, cb

updateRepo = (foldername, cb) ->
    httpsload "https://api.github.com/repos/CorySimmons/jeet", (err, res) ->
        return cb() if err
        try
            data = JSON.parse(res)
            fs.readFile foldername + "/.latest", (err, d) ->
                if d.toString() isnt data.pushed_at
                    pullFromGithub foldername, (err) ->
                        if not err
                            fs.writeFileSync(foldername + "/.latest", data.pushed_at)
                        cb()
                else
                    cb()
        catch e
            cb()
exports = module.exports = (name) ->
    foldername = __dirname.split("/")
    foldername = foldername.slice(0, foldername.length-1).join("/") + "/jeet"
    updateRepo foldername, () ->
        ignore = ["README.md", "watch"]
        localpath = "./" + name + "/"
        if name is "." or name is "./"
            localpath = "./"
            name = process.cwd().split("/").pop()

        if localpath is "./"
            if fs.existsSync "./css/jeet.styl"
                console.log "this is already a jeet project"
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


