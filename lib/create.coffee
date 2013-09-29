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

mkdirp = (lp, path) ->
    path = path.split("/")
    cp = lp
    for p in path
        cp += p + "/"
        if not fs.existsSync cp
            fs.mkdirSync(cp)

exports = module.exports = (name) ->
    foldername = __dirname.split("/")
    foldername = foldername.slice(0, foldername.length-1).join("/") + "/jeet"
    localpath = "./" + name + "/"
    if fs.existsSync localpath
        console.log name + " already exists"
        process.kill()
    else
        fs.mkdirSync(localpath)
    getFiles foldername, (err, files) ->
        (cycle = ()->
            if files.length is 0
                console.log "Created project \x1B[0;1m" + name + "\x1B[0;0m"
            else
                file = files.shift()
                rfile = file.substr(foldername.length + 1)
                path = rfile.split("/")
                rfile = path.pop()
                path = path.join("/")
                mkdirp(localpath, path)
                ws = fs.createWriteStream(localpath + path + "/" + rfile);
                fs.createReadStream(file).pipe(ws);
                ws.on "close", () ->
                    cycle()
        )()


