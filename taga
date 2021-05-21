# !/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键打tag test_v6.2.8_20200113
#

if [ $# -lt 1 ] ; then
	echo "Usage: taga env_name [index]"
	echo "example: taga test"
	echo "example: taga test 1"
	exit 1
fi

branch_name=`git symbolic-ref --short -q HEAD`

today=`date +%Y%m%d`

tag_name=${1}"_"${branch_name}"_"$today

if [ $# = 2 ] ; then
	tag_name=${tag_name}"_"${2}
fi

echo $tag_name

git pull --rebase

git push

git tag $tag_name

git push origin $tag_name
