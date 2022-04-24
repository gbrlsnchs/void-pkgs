#!/bin/sh

for dir in log; do
	mkdir --parents out/$dir
	rm --recursive --force out/$dir/*
done
