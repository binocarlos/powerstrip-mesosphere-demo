/*global Backbone */
var app = app || {};

(function () {
  'use strict';

  // Todo Model
  // ----------

  // Our basic **Todo** model has `title`, `order`, and `completed` attributes.
  app.Todo = Backbone.Model.extend({
    // Default attributes for the todo
    // and ensure that each todo created has `title` and `completed` keys.
    defaults: {
      title: '',
      completed: false
    },

    idAttribute: "_id",

    url: function() { 
      if( this.isNew() ){
        return this.collection.url;
      }else{
        return this.collection.url + '/' + this.get('_id')
      }
    },

    // Toggle the `completed` state of this todo item.
    toggle: function () {
      this.save({
        completed: !this.get('completed')
      },{patch:true});
    }
  });
})();