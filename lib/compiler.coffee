stylus = require "stylus"
fs = require "fs"
autoprefixer = require "autoprefixer"
cleancss = require "clean-css"

exports = module.exports = (path, outname, outpath, cb) ->
    if not fs.existsSync path + outname + ".styl"
        console.log("\x1B[0;31mAborting: Can't find " + outname + ".styl\x1B[0;0m")
        process.kill()
    file = fs.readFileSync path + outname + ".styl"
    stylus(file.toString()).set('paths', [path]).render (err, css) ->
        if err
            msg = err.message.split "\n"
            fileline = msg.shift().split ":"
            linenumber = fileline.pop()

            filename = outname + ".styl"
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
            return
        else
            reload = true
            if not outpath
                outpath = path
                reload = false
            outpath = outpath + "/" if outpath.charAt(outpath.length-1) isnt "/"
            if not fs.existsSync outpath
                fs.mkdirSync outpath

            #prefix and minify css
            css = cleancss.process autoprefixer.compile(css)

            fs.writeFile outpath + outname + ".css", css, () ->
                console.log "Recompiled " + outname + ".styl"
                cb(outpath + outname + ".css") if reload
