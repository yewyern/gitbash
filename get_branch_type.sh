#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 判断分支类型，返回值：
# 0 - 分支不存在
# 1 - 本地分支，无远程
# 2 - 远程分支
#
# @author: 徐宙
# @date: 2020-12-08

function get_branch_type() {
  # 判断远程分支是否存在
  if [ $(git ls-remote --heads $(git remote | head -1) "$1" | cut -d$'\t' -f2 | sed 's,refs/heads/,,' | grep ^"$1"$ | wc -l) != 0 ]; then
    echo 2
  # 判断只存在于本地，没有远程的分支
  elif [ -z "$(git branch --list $1)" ]; then
    echo 0
  else
    echo 1
  fi
}

get_branch_type "$@"