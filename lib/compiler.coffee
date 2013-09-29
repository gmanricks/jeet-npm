stylus = require "stylus"
axis = require "axis-css"
fs = require "fs"

exports = module.exports = (path) ->
    file = fs.readFileSync path + "custom.styl"
    stylus(file.toString()).set('paths', [path]).use(axis()).render (err, css) ->
        if err
            msg = err.message.split "\n"
            fileline = msg.shift().split ":"
            linenumber = fileline.pop()

            filename = "custom.styl"
            if fileline[0] isnt "stylus"
                filename = fileline[0].split("/").pop()

            for i, line of msg
                msg[i] = "\x1B[0;1m" + line + "\x1B[0;0m" if line.charAt(1) is ">"

            msg.pop()
            msg.push("\x1B[0;31m" + msg.pop() + "\x1B[0;0m")
            console.log "\x1B[0;31mError\x1B[0;0m in\x1B[0;1m " + filename + "\x1B[0;0m on line \x1B[0;1m" + linenumber + "\x1B[0;0m"
            console.log "````````````````````````````````````"
            console.log msg.join("\n")
            console.log "````````````````````````````````````"
        else
            fs.writeFile path + "custom.css", css, () ->
                console.log "\x1B[0;32mRecompiled custom.styl\x1B[0;0m"

