#!/usr/bin/env bash
set -o errexit

bundle install
SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
bin/rails db:migrate