#!/bin/bash

# Example .env generator
sed 's/=.*/=/' .env.psql > .env.psql.example
