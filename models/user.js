var mongoose = require('mongoose');
var Schema = mongoose.Schema;
var ObjectId = Schema.ObjectId;

var userSchema = new Schema({
  email: {type: String, index: {unique: true}, required: true},
  password: {type: String, required: true},
  identifier: {type: String, required: true}
});

mongoose.model('User', userSchema, 'users');
