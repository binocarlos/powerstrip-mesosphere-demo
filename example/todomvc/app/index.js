var Hapi        = require('hapi');
var dbOpts      = require('./config.js').mongo;
var Mongoose    = require('mongoose');
var server      = new Hapi.Server();

var connectWithRetry = function() {
  return Mongoose.connect(dbOpts.url, function(err) {
    if (err) {
      console.error('Failed to connect to mongo on startup - retrying in 5 sec', err);
      setTimeout(connectWithRetry, 5000);
    }
  });
};
connectWithRetry();

server.connection({
    port: parseInt(process.env.PORT) || 80,
    routes: {cors: true}
});

var plugins = [ { register: require('./routes.js') }];

server.register(plugins, function (err) {
    if (err) { throw err; }
    server.start(function () {
       console.log('Server running at:', server.info.uri);
    });
});
