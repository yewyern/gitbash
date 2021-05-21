#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键切换分支
# @author: 徐宙
# @date: 2020-12-08

function success_log() {
  echo -e "\033[32m $* \033[0m"
}

function error_log() {
  echo -e "\033[31m $* \033[0m"
}

function setRemoteUrl() {
  git remote set-url origin $target_br
  return 1
}

if [ $# -lt 1 ]; then
  error_log "Usage: cb.sh filename"
  error_log "example: cb.sh brach_list.txt"
  error_log "brach_list.txt like this: "
  error_log "test1	dev"
  error_log "test2	dev"
  exit 1
fi

filename=$1
# 取当前目录
base_dir=`pwd`
# 遍历文件，每次处理一行
while read line || [[ -n $line ]]; do
  line=`echo $line | tr --delete '\n'`
  line=`echo $line | tr --delete '\r'`
  # 跳过以"#"号开头的行，可以注释某些行，更灵活
  if [[ -z "$line" ]] || [[ ${line:0:1} == "#" ]]; then
    continue
  fi
  success_log
  success_log "当前行：$line"
  # 根据空格或tab分割字符串
  arr=($line)
  # 第一个是项目
  project=${arr[0]}
  # 目标分支
  target_br=${arr[1]}
  # 打开文件夹
  cd $base_dir/$project
  success_log "当前目录：`pwd`"
  # 切换分支
  setRemoteUrl $target_br
  success_log "-----------------------"
done < $filename