
function Util() {
  var that = Object.create(Util.prototype);

  return that;
}

// Computes the distance between two objects with latitude and longitude
// properties
Util.globalDist = function(a, b) {
  a_lat = a.latitude;
  a_lng = a.longitude;
  b_lat = b.latitude;
  b_lng = b.longitude;

  return Math.sqrt(Math.pow(a_lat - b_lat, 2) +
                   Math.pow(a_lng - b_lng, 2));
}

// Given a user's location, returns an array that is sorted by
// closest elements first
Util.sortByDistance = function(array, user_loc) {
  array.sort(function(a, b) {
    return Util.globalDist(a, user_loc) > Util.globalDist(b, user_loc);
  });

  return array;
}

Util.checkAuth = function(req, res, next){

  if (!req.session.user){
        res.json({status: 'not ok', message: 'not authenticated'})
        res.end();
        return;
    }
    next();
}


module.exports = Util;
