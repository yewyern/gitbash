#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 添加文件
# @author: 徐宙
# @date: 2020-12-08

function success_log() {
  echo -e "\033[32m $* \033[0m"
}

function error_log() {
  echo -e "\033[31m $* \033[0m"
}

if [ $# -lt 1 ]; then
  error_log "Usage: commitAndPush.sh message"
  exit 1
fi

if [[ -z "$(git status --porcelain)" ]]; then
  error_log "没有待提交文件"
  exit 1
fi
git add .
git commit -m "$1"
git push