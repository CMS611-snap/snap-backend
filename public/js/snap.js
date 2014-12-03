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

  $('#stopGameButton').click(function() {
    console.log("Stopping Game...");
    socket.emit('stop game');
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

  socket.on('game started', function(info) {
    console.log('game started');
    console.log(info);
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
    $('#info').append("winners: " + data.winners.join(", ") + '<br>');
    var scores = [];
    for (var i = 0; i < data.scores.length; i++) {
        var score = data.scores[i];
        scores.push(score.player + ": " + score.score);
    }
    $('#info').append("scores: " + scores.join(", ") + '<br>');
  });

  socket.on('disconnect', function() {
    $('#info').empty();
  })

  var words = [];

  var updateWordCloud = function(data) {
    var words = data.words;
    var wordsListed = '';
    for (var i = 0; i < words.length; i++) {
      wordsListed += words[i].text + ': ' + words[i].score + '<br/>'
    }
    $('#wordlist').html(wordsListed);

    d3.select("#graph").select("svg").remove();

    wordcloud.words(words);
    wordcloud.start();
  }

  socket.on('wordcloud', function(data) {
    console.log('wordcloud ' + JSON.stringify(data));
    updateWordCloud(data);
  });

  $.get("/rpc/wordcloud", function(data) {
      console.log('wordcloud ' + JSON.stringify(data));
      updateWordCloud(data);
  });

  $.get('/rpc/setup/endConfig', function(data) {
      function isPresent(val) {
          return (val && val != 0 && !isNaN(val));
      }
      if (isPresent(data.maxSeconds)) {
          $("#endTime").val(data.maxSeconds);
      }
      if (isPresent(data.maxScore)) {
          $("#endScore").val(data.maxScore);
      }
      if (isPresent(data.maxWords)) {
          $("#endWords").val(data.maxWords);
      }
  });

  $("#endForm").submit(function() {
      $.post("/rpc/setup/endConfig", {
          "maxSeconds": parseInt($("#endTime").val()),
          "maxScore": parseInt($("#endScore").val()),
          "maxWords": parseInt($("#endWords").val())
      });
      return false;
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
