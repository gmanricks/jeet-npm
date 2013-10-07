fs = require "fs"
https = require "https"
crypto = require "crypto"
path = require "path"

ignore = ["README.md", "watch", "bower.json", "package.json"]

exports = module.exports = {}

#Helper method to get HTTPS data as json
getJSON = (url, cb) ->
    https.get(url, (res) ->
        data = ""
        res.on "data", (d) ->
            data += d.toString()
        res.on "end", () ->
            try
                data = JSON.parse(data)
                return cb(false, data)
            catch e
                return cb(e)
    ).on "error", (e) ->
        return cb(e)


#Get list of files with sha1 hashes
getReposFileHashes = (url, cb) ->
    results = []
    getJSON url, (err, json) ->
        return cb(err) if err
        i = 0
        (next = () ->
            file = json[i++]
            return cb(false, results) if not file
            if file.name.charAt(0) is "." or ignore.indexOf(file.name) isnt -1
                next()
            else
                if file.type is "dir"
                    getReposFileHashes file.url, (err, res) ->
                        return cb(err) if err
                        results = results.concat res
                        next()
                else
                    results.push file
                    next()
        )()


#Helper to get Sha1 Hash
getShaForFile = (fpath, cb) ->
    shasum = crypto.createHash "sha1"
    s = fs.ReadStream fpath
    s.on "data", (d) ->
        shasum.update(d)
    s.on "end", () ->
        cb(false, shasum.digest("hex"))
    s.on "error", (e) ->
        cb(e)


#Helper to filter file list down if not required
skipUpToDate = (localFolder, files, cb) ->
    localFolder = path.normalize(localFolder + path.sep)
    results = []
    i = 0
    (next = () ->
        file = files[i++]
        return cb(false, results) if not file
        lp = path.normalize(localFolder + file.path)
        fs.exists lp, (exists) ->
            if exists
                getShaForFile lp, (err, hash) ->
                    return cb(err) if err
                    if hash isnt file.sha
                        results.push file
                    next()
            else
                results.push file;
                next()
    )()

downloadGithubFiles = (fpath, files, cb) ->
    fpath = path.normalize(fpath + path.sep)
    (cycle = () ->
        if files.length is 0
            cb(false)
        else
            file = files.shift()
            getJSON file.url, (err, json) ->
                cb(err) if err
                if json.content or json.size is 0
                    contents = ""
                    if json.size isnt 0
                        contents = new Buffer(json.content, "base64")
                    fs.writeFile path.normalize(fpath + file.path), contents, (err) ->
                        return cb(err) if err
                        cycle()
                else
                    cb(true)
    )()

exports.updateByRepo = (username, reponame, fpath, cb) ->
    url = "https://api.github.com/repos/" + username + "/" + reponame + "/contents/"
    console.log "Checking for updates to Jeet"
    getReposFileHashes url, (err, gfiles) ->
        #ToDo Remove files that are no longer in the repo
        return cb(err) if err
        skipUpToDate fpath, gfiles, (err, files) ->
            return cb(err) if err
            if files.length is 0
                console.log "No new updates"
                return cb(false)
            else
                downloadGithubFiles fpath, files, (err) ->
                    return cb(err) if err
                    console.log "Update Complete"
                    return cb(false)


