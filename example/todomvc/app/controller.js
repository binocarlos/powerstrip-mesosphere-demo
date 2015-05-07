var Todo        = require('./todo.js').Todo;
var Hapi        = require('hapi');

var save = function(request, reply){
   todo = new Todo();
   todo.title = request.payload.title;
   todo.order = request.payload.order;

   todo.save(function (err) {
    if (!err) {
      reply(todo);
    } else {
      console.error(err)
      reply(new Error(err));
    }
   });
};

var update = function(request, reply){
  delete(request.payload._id)
   Todo.findOneAndUpdate({
     _id:request.params.id
   }, request.payload, function (err, todo) {
    if (!err) {
      reply(todo);
    } else {
      console.error(err)
      reply(new Error(err));
    }
  });
};

var getAll = function(request, reply){
  var todosWithUrl = [];
  Todo.find({}, function (err, todos) {
      if (!err) {
         reply(todos);
      } else {
        reply(err);
      }
   });
};

var getById = function(request, reply){
   Todo.findById(request.params.id, function(err, todo){
      if (err){
	       reply(err);
      }
      reply(todo);
   });
};

var deleteAll = function(request, reply) {
   Todo.remove({}, function (err, todos) {
       if (err) return reply(new Error(err));
       return reply("Deleted all todos");
    });
};

var deleteById = function(request, reply) {
    Todo.findById(request.params.id, function (err, todo){
        if (err) return reply(new Error(err));
        todo.remove();
        reply("Record Deleted");
    });
};

var controller = {
    save: save,
    update: update,
    getAll: getAll,
    deleteAll: deleteAll,
    getById: getById,
    deleteById: deleteById,
}

module.exports = controller;