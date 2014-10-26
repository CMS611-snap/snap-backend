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
    console.log('user joined: ' + data.player);
  });
});
