#!/bin/sh

release_ctl eval --mfa "Transport.ReleaseTasks.migrate/1" --argv -- "$@"