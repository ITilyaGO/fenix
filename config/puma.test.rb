#!/usr/bin/env puma

environment 'test'

daemonize

stdout_redirect 'log/stdout.test.log', 'log/stderr.test.log', true

pidfile 'tmp/pids/puma.pid'

threads 0, 4

bind 'tcp://127.0.0.1:3038'