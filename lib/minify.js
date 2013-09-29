// Generated by CoffeeScript 1.5.0
(function() {
  var exports, fs, getFiles, uglify;

  uglify = require("uglify-js");

  fs = require("fs");

  getFiles = function(dir, done) {
    var results;
    results = [];
    return fs.readdir(dir, function(err, list) {
      var i, next;
      if (err) {
        return done(err);
      }
      i = 0;
      return (next = function() {
        var file;
        file = list[i++];
        if (!file) {
          return done(null, results);
        }
        if (file.charAt(0) === "." || file === "minified.js" || file.substr(0, 6) === "jquery" || file.substr(0, 9) === "modernizr" || file.substr(0, 11) === "selectivizr") {
          return next();
        } else {
          file = dir + '/' + file;
          return fs.stat(file, function(err, stat) {
            if (stat && stat.isDirectory()) {
              return getFiles(file, function(err, res) {
                results = results.concat(res);
                return next();
              });
            } else {
              if (file.substr(-3) === ".js") {
                results.push(file);
              }
              return next();
            }
          });
        }
      })();
    });
  };

  exports = module.exports = function(path) {
    return getFiles(path, function(err, files) {
      var data;
      data = uglify.minify(files);
      fs.writeFileSync(path + "/minified.js", data.code);
      return console.log("Recompiled JS into minified.js");
    });
  };

}).call(this);