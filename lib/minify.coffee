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
        toplevel = null
        for file in files
            code = fs.readFileSync(file).toString();
            try
                toplevel = uglify.parse code, { filename: file, toplevel: toplevel }
            catch e
                console.log "\x1B[0;31mJS Error\x1B[0;0m in \x1B[0;1m" + file.split("/").pop() + "\x1B[0;0m on line \x1B[0;1m" + e.line + "\x1B[0;0m"
                console.log "````````````````````````````````````"

                code = code.split("\n");
                if code[code.length-1] is ""
                    code.pop()
                lines = code.length
                start = Math.max(0, e.line - 3)
                end = start + 5
                if end > lines
                    if start > 1 and (end-lines) > 1
                        start -= 2
                        end = Math.min(end-2, lines)
                    else if start > 0
                        start -= 1
                        end = Math.min(end-1, lines)
                    else
                        end = lines

                code = code.slice(start, end)
                for i, line of code
                    i++
                    i+= start
                    if i is e.line
                        console.log "\x1B[0;1m > " + i + "| " + line + "\x1B[0;0m"
                    else
                        console.log "   " + i + "| " + line

                console.log "\n\x1B[0;31m" + e.message + "\x1B[0;0m"
                console.log "````````````````````````````````````"
                return
        stream = uglify.OutputStream({});
        toplevel.print(stream);
        fs.writeFileSync path + "/minified.js", stream.toString()
        console.log "Recompiled JS into minified.js"