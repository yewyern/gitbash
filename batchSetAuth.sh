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
  # 此处是默认了远程仓库名为origin，如果有设置多个远程仓库的，需要修改仓库名
  git remote set-url origin $target_br
  return 1
}

function getRemoteUrl() {
  # 此处是默认了远程仓库名为origin，如果有设置多个远程仓库的，需要修改仓库名
  return $(git remote get-url origin)
}


function set_auth_with_project() {
  project_dir=$1
  username=$2
  password=$3
  # 打开文件夹
  cd "$project_dir" || exit
  curr_dir=$(pwd)
  success_log "当前目录：$curr_dir"

  # 切换分支
  remote_url=$(getRemoteUrl)
  success_log "当前远程路径："$remote_url
}

function batch_set_auth() {
  filename=$1

  # 取当前目录
  base_dir=$(pwd)

  # 去除以#开头的行和空行
  OLD_IFS=$IFS
  echo $OLD_IFS
  IFS=$'\n'
  lines=($(sed '/^#.*$/d' "$filename" | sed '/^$/d'))
  IFS=$OLD_IFS
  for i in "${!lines[@]}";
  do
    line=${lines[$i]}
    # 字符串拼接可以放到双引号内，也可以放到双引号外，放到双引号内可能出现问题，丢失部分字符，原因未知
    success_log "当前行："$line
    set_auth_with_project $line
    success_log "-----------------------"
    success_log
  done
}

if [ $# -lt 1 ]; then
  error_log "Usage: cb.sh [-y] filename [branch_index]"
  error_log "example: cb.sh brach_list.txt"
  error_log "example: cb.sh brach_list.txt 2"
  error_log "example: cb.sh -y brach_list.txt 2"
  error_log "brach_list.txt like this: "
  error_log "test1	dev	test master"
  error_log "test2	dev	test master"
  exit 1
fi

batch_set_auth "$@"