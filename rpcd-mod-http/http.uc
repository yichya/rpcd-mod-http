#!/usr/bin/ucode
'use strict';
const http = require("http");

return {
    http: {
        get: {
            args: {
                addr: "127.0.0.1",
                port: 18888,
                path: "/debug/vars",
                headers: [],
                format: "json"
            },
            call: function (request) {
                const result = http.get(request.args.addr, request.args.port, request.args.path, request.args.headers);
                if (request.args.format == "json") {
                    request.reply({
                        status: result.status,
                        code: result.code,
                        headers: result.headers,
                        json: json(result.body)
                    });
                } else {
                    request.reply({
                        status: result.status,
                        code: result.code,
                        headers: result.headers,
                        text: result.body
                    });
                }
            }
        }
    }
};
