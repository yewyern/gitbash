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

if [ $# -lt 1 ]; then
  error_log "Usage: "
  error_log "cb.sh <options> <parameters>"
  error_log "cb.sh [-y] filename [branch_index]"
  error_log "example: cb.sh brach_list.txt"
  error_log "example: cb.sh brach_list.txt 2"
  error_log "example: cb.sh -y brach_list.txt 2"
  error_log "brach_list.txt like this: "
  error_log "test1	dev	test master"
  error_log "test2	dev	test master"
  exit 1
fi

# 获取脚本文件所在路径
BASH_HOME=$(dirname $(readlink -f "$0"))

function batch_switch_branch() {
  options=
  if [[ "$1" == "-y" ]]; then
    options=$1
    shift 1
  fi
  filename=$1
  branch_index=$2
  if [ -z "$branch_index" ]; then
    branch_index=1
  fi
  # 取当前目录
  base_dir=`pwd`
  # 一次读取所有行到数组
  mapfile lines < $filename
  # 遍历数组
  for i in "${!lines[@]}";
  do
    line=${lines[$i]}
    # 过滤空行和#号开头的
    if [[ -z "$line" ]] || [[ ${line:0:1} == "#" ]]; then
      continue
    fi
    # 处理换行符
    line=`echo $line | tr --delete '\n'`
    line=`echo $line | tr --delete '\r'`
    # 过滤空行
    if [[ -z "$line" ]]; then
      continue
    fi
    success_log
    success_log "当前行：$line"
    # 根据空格或tab分割字符串
    arr=($line)
    # 第一个是项目
    project=${arr[0]}
    # 目标分支
    target_br=${arr[$branch_index]}
    # 打开文件夹
    cd "$base_dir/$project" || exit
    success_log "当前目录：`pwd`"
    # 查看当前分支
    curr_br=`git symbolic-ref --short -q HEAD`
    success_log "当前分支：$curr_br"
    success_log "目标分支：$target_br"
    # 切换分支
    sh "$BASH_HOME/switch_branch.sh" $options $target_br
    success_log "-----------------------"
  done
}

batch_switch_branch "$@"