#!/usr/bin/ucode
'use strict';
const ctypes = require("ctypes");
const struct = require("struct");

const abbreviation_to_ffi = {
    h: ctypes.ffi_type.sint16,
    H: ctypes.ffi_type.uint16,
    i: ctypes.ffi_type.sint32,
    I: ctypes.ffi_type.uint32,
    N: ctypes.ffi_type["uint" + length(struct.pack("N")) * 8],
    P: ctypes.ffi_type.pointer,
};

function attach(dl_handle, name, params) {
    const params_list = split(params, "");
    const cif = ctypes.prep(ctypes.const.FFI_DEFAULT_ABI, ...map(params_list, (a) => abbreviation_to_ffi[a]));
    return function (...args) {
        const packed = struct.pack(params, 0, ...args);
        const return_buffer = ctypes.ptr(packed);
        const s = ctypes.symbol(dl_handle, name);
        assert(s != null);
        assert(cif.call(s, return_buffer));
        return struct.unpack(substr(params, 0, 1), return_buffer.ucv_string_new())[0];
    };
}

const c = {
    strlen: attach(ctypes.const.RTLD_DEFAULT, "strlen", "NP"),
    strerror: attach(ctypes.const.RTLD_DEFAULT, "strerror", "Pi"),
};

function strerror(eno) {
    assert(eno != null);
    let return_ptr = c.strerror(eno);
    let len = c.strlen(return_ptr);
    return ctypes.ptr(return_ptr).ucv_string_new(len);
}

c.socket = {
    AF_INET: 2,
    SOCK_STREAM: 1,
    IPPROTO_TCP: 6,
    socket: attach(ctypes.const.RTLD_DEFAULT, "socket", "iiii"),
    inet_pton: attach(ctypes.const.RTLD_DEFAULT, "inet_pton", "iiPN"),
    connect: attach(ctypes.const.RTLD_DEFAULT, "connect", "iiPN"),
    send: attach(ctypes.const.RTLD_DEFAULT, "send", "NiPNi"),
    recv: attach(ctypes.const.RTLD_DEFAULT, "recv", "NiPNi"),
    close: attach(ctypes.const.RTLD_DEFAULT, "close", "ii"),
};

function connect(fd, straddr, port) {
    const straddr_ptr = ctypes.ptr(straddr);
    const inaddr_ptr = ctypes.ptr(struct.pack("4x"));
    const return_int = c.socket.inet_pton(c.socket.AF_INET, straddr_ptr.as_int(), inaddr_ptr.as_int());
    assert(return_int == 1);

    const inaddr_arr = struct.unpack("4b", inaddr_ptr.ucv_string_new());
    const sockaddr_buf = struct.pack("H", c.socket.AF_INET) + struct.pack(">H", port) + struct.pack("4b8x", ...inaddr_arr);
    const sockaddr_ptr = ctypes.ptr(sockaddr_buf);

    return c.socket.connect(fd, sockaddr_ptr.as_int(), length(sockaddr_buf));
}

function send(fd, buf, flags) {
    const buf_ptr = ctypes.ptr(buf);
    const buf_size = c.strlen(buf_ptr.as_int());
    return c.socket.send(fd, buf_ptr.as_int(), buf_size, flags);
}

function recv(fd, flags) {
    const buflen = 4096;
    const buf_ptr = ctypes.ptr(struct.pack(sprintf("%dx", buflen)));
    let result = "";
    while (true) {
        const ret = c.socket.recv(fd, buf_ptr.as_int(), buflen, flags);
        if (ret <= 0) {
            break;
        }
        const part = buf_ptr.ucv_string_new(ret);
        result = result + part;
        // hack http end condition (really hack here)
        const s = split(result, "\r\n\r\n");
        if (length(s) == 3) {
            break;
        }
    }
    return result;
}

// response: [404, "Not Found", {"Connection": "Close"}, "Not Found"]
function http_body_parse(raw, format) {
    // headers and body
    const s = split(raw, "\r\n\r\n");
    const h = split(s[0], "\r\n");
    const status = split(h[0], " ", 3);
    let headers = {};
    for (let i = 1; i < length(h); i++) {
        const kv = split(h[i], ":", 2);
        headers[trim(kv[0])] = trim(kv[1]);
    }
    let body = "";
    // squash chunked here (really hack again)
    if (headers["Transfer-Encoding"] == "chunked") {
        const ss = split(s[1], "\r\n");
        for (let j = 1; j < length(ss); j = j + 2) {
            body = body + ss[j];
        }
    } else {
        body = s[1];
    }
    return {
        code: int(status[1]),
        status: status[2],
        headers: headers,
        body: body,
    }
}

// response: ["http", 404, "Not Found", {"Connection": "Close"}, ""]
function get(host, port, path, headers) {
    const fd = c.socket.socket(c.socket.AF_INET, c.socket.SOCK_STREAM, c.socket.IPPROTO_TCP);
    if (fd < 0) {
        const errno = ctypes.errno();
        const errno_str = strerror(errno);
        return {
            code: 0 - errno,
            status: strerror(errno),
            headers: [],
            body: `"${errno_str}"`,
        }
    }
    if (connect(fd, host, port) != 0) {
        const errno = ctypes.errno();
        const errno_str = strerror(errno);
        return {
            code: 0 - errno,
            status: strerror(errno),
            headers: [],
            body: `"${errno_str}"`,
        }
    }
    // todo: fill headers here
    const send_result = send(fd, sprintf("GET %s HTTP/1.1\r\nHost: %s\r\nConnection: Close\r\n\r\n\r\n\r\n", path, host), 0);
    if (send_result < 0) {
        const errno = ctypes.errno();
        const errno_str = strerror(errno);
        return {
            code: 0 - errno,
            status: strerror(errno),
            headers: [],
            body: `"${errno_str}"`,
        }
    }
    const result = recv(fd, 0);
    c.socket.close(fd);
    return http_body_parse(result);
}

return {
    get: get,
}
