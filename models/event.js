var mongoose = require('mongoose');
var Schema = mongoose.Schema;
var ObjectId = Schema.ObjectId;


var eventSchema = Schema({
  type: String,
  timestamp: Number,
  creator: ObjectId,
  group: [ObjectId],
  latitude: Number,
  longitude: Number,
  location_name: String
});

mongoose.model('Event', eventSchema, 'events');
