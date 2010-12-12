var connect = require('connect');
var fs = require('fs');

var keys = [];

connect.createServer(
  connect.staticProvider('./'),
  connect.router(function(app) {
    app.get('/key/:key', function (req, res, next) {
      var found = false;
      
      for (var i = 0; i < keys.length; i++) {
        if (keys[i] == req.params.key) found = true;
      }
      
      if (found == false) keys.push(req.params.key);
      
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.end(keys.join('<br>'));
    });
    
    app.get('/', function(req, res, next) {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.end(fs.readFileSync('./Camera.html'));
    });
  })
).listen(4239);
