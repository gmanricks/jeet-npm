jade = require "jade"
fs = require "fs"

exports = module.exports = (path) ->
    script = fs.readFile path, (err, data)->
        return err if err
        html = ""
        code = data.toString()
        try
            html = jade.compile(code, { pretty: true })
        catch e
            msg = e.message.split "\n"
            fileline = msg.shift().split ":"
            linenumber = fileline.pop()

            console.log "\x1B[0;31mJade Error\x1B[0;0m in \x1B[0;1m" + path.split("/").pop() + "\x1B[0;0m on line \x1B[0;1m" + linenumber + "\x1B[0;0m"
            console.log "````````````````````````````````````"

            for i, line of msg
                msg[i] = "\x1B[0;1m" + line + "\x1B[0;0m" if line.charAt(2) is ">"

            #msg.pop()
            msg.push("\x1B[0;31m" + msg.pop() + "\x1B[0;0m")

            console.log msg.join("\n")
            console.log "````````````````````````````````````"
            return
        newPath = path.substr(0, path.length-5) + ".html"
        fs.writeFile  newPath, html(), (err) ->
            return if err
            console.log "Recompiled " + path.split("/").pop()
