const Users = require('../../models/User');

function getUsers() {
    return new Promise(function(resolve) {
        Users.find({}, function(err, users) { resolve(users); })
    });
}

module.exports = getUsers;
