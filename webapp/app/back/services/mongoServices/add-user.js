const User = require('../../models/User');

function addUser(username) {
    return new Promise(function(resolve, reject) {
        const userRecord = new User({ username: username });
        userRecord.save(function (err) {
            if (err) { reject(err); }
            resolve();
        });
    });
}

module.exports = addUser;
