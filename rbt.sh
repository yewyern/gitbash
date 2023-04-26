#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 以本分支为根基，合并到目标分支
#

if [ $# -lt 1 ] ; then
	echo "Usage: rbt to_branch_name"
	echo "example: rbt dev"
	git branch
	exit 1
fi

branch_name=`git symbolic-ref --short -q HEAD`

to_branch_name=$1

echo "以$branch_name为根基，合并到$to_branch_name"

git rebase $branch_name $to_branch_name