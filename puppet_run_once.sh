#!/bin/bash
# run puppet from cron with splay time

sleep $(($RANDOM % 300))

/usr/sbin/puppetd --onetime --server puppet

