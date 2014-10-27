$(function() {

  var socket = io();

  $('#joinButton').click(function() {
    var username = $('#playerName').val();
    console.log("ADDUSER: " + username);
    socket.emit('new player', username);
  });

  $('#wordButton').click(function() {
    var word = $('#newWord').val();
    console.log("WORDBUTTON: " + word);
    socket.emit('new word', word);
  });

  socket.on('user joined', function(data) {
    console.log('user joined: ' + data);
    $('#info').append(JSON.stringify(data) + '<br>');
  });

  socket.on('snap', function(data) {
    console.log('snap ' + data);
    $('#info').append(JSON.stringify(data) + '<br>');
  });

  socket.on('disconnect', function() {
    $('#info').empty();
  })

});
