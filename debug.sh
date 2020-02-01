#!/bin/bash

typeset PUB=/usr/lib/dart/bin/pub
export https_proxy="http://10.230.1.1:8080"
export no_proxy="127.0.0.1,localhost"
echo "======================"
echo "refreshing build stack"
echo "======================"
$PUB get
$PUB global activate webdev
echo 
echo "======================"
echo "running debug"
echo "======================"
$PUB global run webdev serve web:3001

echo "======================"
echo "FINISHED"
echo "======================"

