#!/usr/bin/env node

var app = require('commander');
var terminal = require('color-terminal');
var download = require('github-download');
var fs = require('fs');
var http = require('http');
var net = require('net');
var stylus = require('stylus');
var nib = require('nib');
var compass = require('compass');
var tinylr = require('tiny-lr');

var livereload = false;
app.version('0.3.1');

app.option('-t, --stylus', 'Only use Stylus');
app.option('-c, --scss', 'Only use SCSS');

app.command('create <app_name>').description("Create a new Jeet app").action(function(app_name) {
	terminal.colorize("\n%W%0%UCreating " + app_name + "%n\n");
	terminal.write("    Downloading Repo ... ");
	download({user: 'CorySimmons', repo: 'jeet'}, process.cwd() + "/." + app_name)
		.on('error', function(err){ 
			terminal.color("red").write(err).reset().write("\n\n");
			process.kill();		
		})
		.on('end', function(){
			fs.renameSync(process.cwd() + "/." + app_name + "/web",  process.cwd() + "/" + app_name);
			deleteFolder(process.cwd() + "/." + app_name);
			terminal.color("green").write("OK!").reset().write("\n\n");
		});
});

app.command('watch').description("Watch the current path and recompile CSS on changes").action(function(){
	var rootPath = getRootPath();
	cssPath = rootPath + "css/";
	terminal.colorize("\n%W%0%UWatching App%n\n");
	compileStylus(cssPath);
	compileSCSS(cssPath);
	startLiveReload(cssPath)
	fs.watch(rootPath, function(e, filename) {
		//var ext = filename.substr(-4);
		//if (ext === "html" || ext === ".css")
		if (livereload) {
			http.get("http://localhost:35729/changed?files=" + filename);
		}
	}); 
	if (fs.existsSync(cssPath + "scss") && !app.stylus) {
		var scssFilesArr = fs.readdirSync(cssPath + "scss");
		for (var i = 0; i < scssFilesArr.length; i++) {
			if (fs.statSync(cssPath + "scss/" + scssFilesArr[i]).isDirectory()) {
				fs.watch(cssPath + "scss/" + scssFilesArr[i], function(e, filename){
					if (filename.substr(-5) === ".scss") {			
						compileSCSS(cssPath);
					}
				});
			}
		}
		fs.watch(cssPath + "scss", function(e, filename){
			if (filename.substr(-5) === ".scss") {		
				compileSCSS(cssPath);
			}
		});
	}
	
	if (fs.existsSync(cssPath + "styl") && !app.scss) {
		var stylFilesArr = fs.readdirSync(cssPath + "styl");
		for (var i = 0; i < stylFilesArr.length; i++) {
			if (fs.statSync(cssPath + "styl/" + stylFilesArr[i]).isDirectory()) {
				fs.watch(cssPath + "styl/" + stylFilesArr[i], function(e, filename){
					if (filename.substr(-5) === ".styl") {			
						compileStylus(cssPath);
					}
				});
			}
		}
		fs.watch(cssPath + "styl", function(e, filename){
			if (filename.substr(-5) === ".styl") {			
				compileStylus(cssPath);
			}
		});
	}
});

app.parse(process.argv);


//Helper Functions

//Function by timoxley on https://gist.github.com/timoxley/1689041
function isPortTaken (PORT, callback) {
  var tester = net.createServer()
  tester.once('error', function (err) {
    if (err.code == 'EADDRINUSE') {
      callback(null, true)
    } else {
      callback(err)
    }
  })
  tester.once('listening', function() {
    tester.once('close', function() {
      callback(null, false)
    })
    tester.close()
  })
  tester.listen(PORT)
}

function startLiveReload(cssPath) {
	isPortTaken(35729, function (err, taken) {
		if (!err && !taken) {	
			tinylr().listen(35729, function(){
				livereload = true;
				terminal.color("green").write("    Live Reload is on and listening !").reset().write("\n\n");   
			});
			//var server = liveReload.createServer({ port: 35729, exts: ['css', 'html']});
			//server.watch(cssPath.substr(0, cssPath.length-4));
		} else if (!err && taken) {
			terminal.color("red").write("    The livereload port seems to be in use by another app, so live-reload will be turned off").reset().write("\n\n");
		} else {
			terminal.color("red").write(err).reset().write("\n\n");
			process.kill();	
		}
	});
}

function getRootPath () {
	var rootPath = process.cwd();
	if (fs.existsSync(rootPath + "/styl") || fs.existsSync(rootPath + "/scss")) {
		rootPath = rootPath.substr(0, -3);
	} else if (fs.existsSync(rootPath + "/css/styl") || fs.existsSync(rootPath + "/css/scss")) {
		rootPath += "/";
	} else if (fs.existsSync(rootPath + "/web/css/styl") || fs.existsSync(rootPath + "/web/css/scss")) {
		rootPath += "/web/";
	} else {
		terminal.color("red").write("This doesn't appear to be a Jeet Project").reset().write("\n\n");
		process.kill();		
	}
	return rootPath;
}

function compileSCSS (cssPath) {
	if (app.stylus) {
		return;
	}
	var scssFile = "";
	if (fs.existsSync(cssPath + "scss/style.scss")) {
		scssFile = cssPath + "scss/style.scss";
	} else if (fs.existsSync(cssPath + "scss/style_scss.scss")) {
		scssFile = cssPath + "scss/style_scss.scss";
	} else {
		//No Scss style file
		return;
	}
	compass.compile({cwd: cssPath + "scss"}, function(err) {
		var message = "    Compiling SCSS ... ";

		if (err) {
			message += "%rError!%n\n\n";		
		} else {
			message += "%gOK!%n\n";
			message += "    Saving Compiled SCSS ... ";
			if (fs.existsSync(cssPath + "style.css")) {
				fs.renameSync(cssPath + "style.css", cssPath + "scss/style_scss.css");
			}
			if (fs.existsSync(cssPath + "style_scss.css")) {
				fs.renameSync(cssPath + "style_scss.css", cssPath + "scss/style_scss.css");
			}						
			message += "%gOK!%N \n\n";	
		}
		
		terminal.colorize(message);
		if (livereload) {
			http.get("http://localhost:35729/changed?files=" + cssPath + "scss/style_scss.css");
		}
	}); 
}

function compileStylus (cssPath) {
	if (app.scss) {
		return;
	}
	var stylFile = "";
	if (fs.existsSync(cssPath + "styl/style.styl")) {
		stylFile = cssPath + "styl/style.styl";
	} else if (fs.existsSync(cssPath + "styl/style_styl.styl")) {
		stylFile = cssPath + "styl/style_styl.styl";
	} else {
		//No STYL style file
		return;
	}
	
	terminal.write("    Compiling Stylus ... ");
	var styleFile = fs.readFileSync(stylFile);
	try {
		styleFile = stylus(styleFile.toString()).set('paths', [cssPath + "styl"]).use(nib()).render();
		terminal.color("green").write("OK!").reset().write("\n");
	
		terminal.write("    Saving Compiled Stylus ... ");
		fs.writeFileSync(cssPath + "styl/style_styl.css", styleFile);
		terminal.color("green").write("OK!").reset().write("\n\n");
		if (livereload) {
			http.get("http://localhost:35729/changed?files=" + cssPath + "styl/style_styl.css");
		}

	} catch (e) {
		terminal.color("red").write("Error!").reset().write("\n\n");
	}
}

//Function Thanks to geedew on SO

function deleteFolder(path) {
    var files = [];
    if( fs.existsSync(path) ) {
        files = fs.readdirSync(path);
        files.forEach(function(file,index){
            var curPath = path + "/" + file;
            if(fs.statSync(curPath).isDirectory()) { // recurse
                deleteFolder(curPath);
            } else { // delete file
                fs.unlinkSync(curPath);
            }
        });
        fs.rmdirSync(path);
    }
};