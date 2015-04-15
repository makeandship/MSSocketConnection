var net = require('net'),
  moviesServer = createServer('movies', 49001),
  imagesServer = createServer('images', 49002);

function createServer(serverName, port) {
  var server = net.createServer(function(c) { //'connection' listener
    console.log('[' + serverName + '] client connected');
    c.on('end', function() {
      console.log('[' + serverName + '] client disconnected');
    });
    c.on('data', function(data) {
      console.log('[' + serverName + '] DATA ' + c.remoteAddress + ': ' + data);
      c.write('Echo: "' + data + '"');
    });
  }).listen(port, function() { //'listening' listener
    console.log('[' + serverName + '] server listening on port ' + port);
  });
  return server;
}