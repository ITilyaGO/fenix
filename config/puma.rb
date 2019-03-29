#!/usr/bin/env puma

environment 'production'

daemonize

stdout_redirect 'log/stdout.log', 'log/stderr.log', true

pidfile 'tmp/pids/puma.pid'

threads 0, 8

# bind 'unix:/var/run/fenix.sock'
bind 'tcp://127.0.0.1:8080'