coffee = require "coffee-script"
fs = require "fs"

exports = module.exports = (path) ->
    script = fs.readFile path, (err, data)->
        return err if err
        js = ""
        code = data.toString()
        try
            js = coffee.compile(code)
        catch e
            e.location.first_line++
            console.log "\x1B[0;31mCoffee Error\x1B[0;0m in \x1B[0;1m" + path.split("/").pop() + "\x1B[0;0m on line \x1B[0;1m" + e.location.first_line + "\x1B[0;0m"
            console.log "````````````````````````````````````"

            code = code.split("\n");
            if code[code.length-1] is ""
                code.pop()
            lines = code.length
            start = Math.max(0, e.location.first_line - 3)
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
                if i is e.location.first_line
                    console.log "\x1B[0;1m > " + i + "| " + line + "\x1B[0;0m"
                else
                    console.log "   " + i + "| " + line

            console.log "\n\x1B[0;31m" + e.message + "\x1B[0;0m"
            console.log "````````````````````````````````````"
            return
        newPath = path.substr(0, path.length-7) + ".js"
        fs.writeFile  newPath, js, (err) ->
            return if err
            console.log "Recompiled " + path.split("/").pop()

