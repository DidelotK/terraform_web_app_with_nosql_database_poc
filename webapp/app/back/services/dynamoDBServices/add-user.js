const AWS = require('aws-sdk');
const uuidv4 = require('uuid/v4');


// Promisify AWS SDK
AWS.config.setPromisesDependency(require('bluebird'));

// Set the region
AWS.config.update({region: 'eu-central-1'});

function addUser(username) {
    // Create DynamoDB service object
    var ddb = new AWS.DynamoDB({apiVersion: '2012-08-10'});

    var params = {
        Item: {
            "UserId": {
                S: uuidv4()
            },
            "Username": {
                S: username
            }
        },
        TableName: 'Users'
    };

    return ddb.putItem(params).promise();
}

module.exports = addUser;
