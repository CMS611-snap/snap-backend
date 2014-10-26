$(function() {

  var socket = io();

  $('#joinButton').click(function() {
    console.log("ADDUSER");

    var username = $('playerName').val();
    socket.emit('new player', username);

  });

});
