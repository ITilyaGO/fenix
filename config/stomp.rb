module Stomp
  DETAILS = {
    hosts: [{ login: 'guest', passcode: 'guest', host: 'localhost', port: 61613 }],
    connect_headers: { 'accept-version': '1.2', host: '/' },
    reliable: false
  }
end