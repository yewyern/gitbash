# !/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键删tag
#

if [ $# != 1 ] ; then
	echo "Usage: tagd tagName"
	echo "example: tagd test_v6.2.8_20200113"
	exit 1
fi

tag_name=$1

git pull

git tag -d $tag_name

git push origin :refs/tags/$tag_name