#!/usr/bin/env puma

# environment 'production'

# daemonize

# stdout_redirect 'log/stdout.log', 'log/stderr.log', true

pidfile 'tmp/pids/puma.pid'

# threads 16, 16

# bind 'unix:/var/run/fenix.sock'
bind 'tcp://0.0.0.0:8101'