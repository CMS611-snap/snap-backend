
function Util() {
  var that = Object.create(Util.prototype);

  return that;
}


// For now, checkAuth does nothing because we have no process for it
Util.checkAuth = function(req, res, next){

    //if (!req.session.user){
        //res.json({status: 'not ok', message: 'not authenticated'})
        //res.end();
        //return;
    //}
    next();
}


module.exports = Util;
