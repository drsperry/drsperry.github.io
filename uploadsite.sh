#!/bin/bash
cd $1
git add .
git commit -m "automatic upload"
git push -u origin master

