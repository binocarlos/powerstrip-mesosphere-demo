var controller = require('./controller.js');
var path = require('path');

exports.register = function(server, options, next) {
    server.route({
        method: 'GET',
        path: '/v1',
        handler: controller.getAll
    });

    server.route({
        method: 'POST',
        path: '/v1',
        handler: controller.save
    });

    server.route({
        method: 'PATCH',
        path: '/v1/{id}',
        handler: controller.update
    });

    server.route({
        method: 'PUT',
        path: '/v1/{id}',
        handler: controller.update
    });

    server.route({
        method: 'DELETE',
        path: '/v1',
        handler: controller.deleteAll
    })

    server.route({
        method: 'GET',
        path: '/v1/{id}',
        handler: controller.getById
    });

    server.route({
        method: 'DELETE',
        path: '/v1/{id}',
        handler: controller.deleteById
    });

    server.route({
        method: 'GET',
        path: '/{path*}',
        handler: {
            directory: {
                path: path.join(__dirname, 'www'),
                index: true
            }
        }
    })

    next();
};

exports.register.attributes = {
    name: 'routes',
    version: '1.0.0'
};
