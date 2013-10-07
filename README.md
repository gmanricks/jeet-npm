Jeet 3 NPM Package
---

[Jeet 3](https://github.com/CorySimmons/jeet) | [Documentation](http://jeetframework.com) | [Demos / Screencasts](http://jeetframework.com/demos) | [NPM package](https://npmjs.org/package/jeet)

Installation:
---

- Install NodeJS
- `npm install -g jeet`
- `jeet -h`

```
Usage: jeet [options] [command]

Commands:
    watch                   watch the current path and recompile CSS on changes
    create <name>           create a new jeet project with the given name

    Options:
        -h, --help          output usage information
        -V/-v, --version    output the version number
        -o, --outpath       the folder to compile the css into
        -n, --name          the name of the styl file [defaults to "custom"]
```

**Note:** If you modify `--outpath` or `--name` you will have to reflect those changes in your `index.html` yourself.

LiveReload Installation
---

- If you're using Sublime Text, disable your LiveReload plugin with it
- Install a LiveReload [browser extension](http://feedback.livereload.com/knowledgebase/articles/86242-how-do-i-install-and-use-the-browser-extensions-)
- Once `jeet watch` is working it will notify you that LiveReload is active, open your browser and activate your LiveReload browser extension (usually just by clicking on it).

CLI Usage
---

- `jeet create foo` or `jeet create .` to dump Jeet into current dir
- `cd foo`
- `jeet watch`

`jeet create` will fetch the latest copy of Jeet from the repo. If it already has the latest copy or you don't have internet access, it will not fetch it and simply use the most recent copy of Jeet the package is equipped with. This makes project creation very fast and makes sure you have the latest/greatest version of Jeet created each time.

Jeet will watch your project for changes to `.styl` files within `/css`. It will concatenate and minify that CSS to `css/custom.css`. Jeet will also watch your `/js` automatically concatenate and minify most of your JavaScript (the ones that aren't already included as oldIE polyfills) including your `plugins.js`, `main.js`, and any new `.js` files in your `/js` dir.

Jeet now also watches CoffeeScript files nested under your `/js` dir.

Jeet 2
---

Jeet 2's NPM package is still available under the [jeet2 branch](https://github.com/CorySimmons/jeet-npm/tree/jeet2)