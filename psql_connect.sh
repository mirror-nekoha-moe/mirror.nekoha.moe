#!/bin/bash
export $(grep -v '^#' ./.env.psql | xargs)
psql