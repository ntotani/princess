var crypto = require('crypto');

var PUSHER_ID = "64710";
var PUSHER_KEY = "753bbbbb0ecb441ce3eb";
var PUSHER_SECRET = "4f5d7566d190aedca695";

var sign = function(str) {
    return crypto.createHmac('sha256', PUSHER_SECRET).update(str).digest('hex');
}

Parse.Cloud.define("pusher", function(request, response) {
    var socketId = request.params.socket_id;
    var channelId = request.params.channel_id;
    if (!channelId) {
        channelId = "" + Math.floor(Math.random() * 100000);
    }
    var data = request.params.data;
    var result = {channel_id:channelId};
    var signatureData = [socketId, "private-" + channelId];
    if (data) {
        var serializedData = JSON.stringify(data);
        signatureData.push(serializedData);
        result.channel_data = serializedData;
    }
    result.auth = PUSHER_KEY + ':' + sign(signatureData.join(":"));
    response.success(result);
});

var push = function(body, success, error) {
    body = JSON.stringify(body);
    var method = "POST";
    var path = "/apps/" + PUSHER_ID + "/events";
    var query = "auth_key=" + PUSHER_KEY;
    query += "&auth_timestamp=" + parseInt(new Date().getTime() / 1000, 10);
    query += "&auth_version=1.0";
    query += "&body_md5=" + crypto.createHash('md5').update(body, 'utf8').digest('hex');
    query += "&auth_signature=" + sign([method, path, query].join('\n'));
    Parse.Cloud.httpRequest({
        method: method,
        url: "http://api.pusherapp.com" + path + "?" + query,
        headers: {
            'Content-Type': 'application/json'
        },
        body: body,
        success: success,
        error: error
    });
}

Parse.Cloud.define("start", function(req, res) {
    var channelId = req.params.channel_id;
    // TODO validate
    var Match = Parse.Object.extend("Match");
    var match = new Match();
    match.save({
        channel: channelId,
        seed: Math.floor(Math.random() * 100000),
        acts: []
    }, {
        success: function(obj) {
            push({
                name: 'start',
                data: JSON.stringify({id: obj.id, seed: obj.get("seed")}),
                channel: 'private-' + channelId
            }, function(httpResponse) {
                res.success(httpResponse.text);
            }, function(httpResponse) {
                res.error(httpResponse.status + ': ' + httpResponse.text);
            });
        },
        error: function(obj, error) {
            res.error(error.message);
        }
    });
});

Parse.Cloud.afterSave("Match", function(request) {
    var acts = request.object.get("acts");
    var red = request.object.get("red");
    var blue = request.object.get("blue");
    // TODO validate
    if (acts.length == 0 && red && blue) {
        push({
            name: 'form',
            data: JSON.stringify({red: red, blue: blue}),
            channel: 'private-' + request.object.get('channel')
        }, function(httpResponse) {
            console.log(httpResponse.text);
        }, function(httpResponse) {
            console.error(httpResponse.status + ': ' + httpResponse.text);
        });
    } else if (acts.length >= 2 && acts.length % 2 == 0) {
        push({
            name: 'turn',
            data: JSON.stringify(acts.slice(-2)),
            channel: 'private-' + request.object.get('channel')
        }, function(httpResponse) {
            console.log(httpResponse.text);
        }, function(httpResponse) {
            console.error(httpResponse.status + ': ' + httpResponse.text);
        });
    }
});
