$(function() {

  var socket = io();
  
  $('#setTopicButton').click(function() {
    var topic = $('#topic').val();
    console.log("Set Topic To: " + topic);
    socket.emit('set topic', topic);
  });  

  $('#startGameButton').click(function() {
    console.log("Starting Game...");
    socket.emit('start game');
  });



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
  socket.on('new topic', function(topic){
    console.log('new topic: ' + topic);
    $('#info').append('TOPIC is : ' + JSON.stringify(topic) + '<br>');
  });

  socket.on('game started', function(){
    console.log('game started');
    $('#info').append('<br>' + 'GAME STARTED!!' + '<br>');
  });

  socket.on('user joined', function(data) {
    console.log('user joined: ' + data);
    $('#info').append(JSON.stringify(data) + '<br>');
  });

  socket.on('snap', function(data) {
    console.log('snap ' + data);
    $('#info').append(JSON.stringify(data) + '<br>');
  });

  socket.on('new word', function(data) {
    console.log('new word ' + data);
    $('#info').append(JSON.stringify(data) + '<br>');
  });

  socket.on('game over', function(data) {
    console.log('game over ' + data);
    $('#info').append(JSON.stringify(data) + '<br>');
  });

  socket.on('disconnect', function() {
    $('#info').empty();
  })


  var words = [{text:"placeholder", size:100}];

  socket.on('wordcloud', function(data) {
    console.log('wordcloud ' + JSON.stringify(data));
    words = data.words;

    d3.select("#graph").select("svg").remove();

    wordcloud.words(words);
    wordcloud.start();
  });




  var fill = d3.scale.category20();

  var wordcloud = d3.layout.cloud()
      .size([300, 300])
      .words(words)
      .padding(5)
      .rotate(function() { return 0; })//~~(Math.random() * 2) * 90; })
      .font("Impact")
      .fontSize(function(d) { return d.size; })
      .on("end", draw)
      .start();


  function draw(words) {
    d3.select("#graph").append("svg")
        .attr("width", 300)
        .attr("height", 300)
      .append("g")
        .attr("transform", "translate(150,150)")
      .selectAll("text")
        .data(words)
      .enter().append("text")
        .style("font-size", function(d) { return d.size + "px"; })
        .style("font-family", "Impact")
        .style("fill", function(d, i) { return fill(i); })
        .attr("text-anchor", "middle")
        .attr("transform", function(d) {
          return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")";
        })
        .text(function(d) { return d.text; });
  }
});
