#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 批量删除文件
# @author: 徐宙
# @date: 2020-12-08

function success_log() {
  echo -e "\033[32m $* \033[0m"
}

function error_log() {
  echo -e "\033[31m $* \033[0m"
}

if [ $# -lt 1 ]; then
  error_log "Usage: batchdel.sh dirname"
  error_log "example: batchdel.sh target"
  exit 1
fi

dirname=$1
find . -name $dirname -type d > batchdel.tmp
# 遍历文件，每次处理一行
while read line || [[ -n $line ]]; do
  success_log "当前行：$line"
  rm -rf $line
done < batchdel.tmp
rm -f batchdel.tmp