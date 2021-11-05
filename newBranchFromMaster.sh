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

function new_branch() {
  options=
  if [[ "$1" == "-y" ]]; then
    options=$1
    shift 1
  fi
  target_br=$1
  branch_type=$(sh "$BASH_HOME/get_branch_type.sh" "$target_br")
  if [ $branch_type = 2 ]; then
    success_log "远程分支已存在，无需创建分支"
    return 1
  fi

  # 如果存在本地分支
  if [ $branch_type = 1 ]; then
#    git checkout $target_br
#    git merge master
#    git push --set-upstream origin $target_br
    error_log "有本地分支，请手动处理"
    return 1
  fi

  # 提示是否进行创建
  if [[ "$options" != "-y" ]]; then
    echo -n "是否进行创建？(y/n)"
    read toContinue
    if [[ "Y" != "$toContinue" && "y" != "$toContinue" ]]; then
      return 1
    fi
  fi

  # 切换分支到master
  sh "$BASH_HOME/switch_branch.sh" -y master
  success_log "当前分支：$curr_br"
  success_log "目标分支：$target_br"

  git checkout -b "$target_br"
  curr_br=$(git symbolic-ref --short -q HEAD)
  if [ "$curr_br" != "$target_br" ]; then
    error_log "** 创建分支失败，当前分支：$curr_br"
    return 0
  fi
  success_log "创建成功，当前分支：$curr_br"
  git push --set-upstream origin "$target_br"
  success_log "已推送至远程"
  return 1
}

if [ $# -lt 2 ]; then
  error_log "Usage: newBranchFromMaster.sh [-y] filename branch_name"
  error_log "example: newBranchFromMaster.sh branch_list.txt pre-develop-t1"
  error_log "branch_list.txt like this: "
  error_log "test1"
  error_log "test2"
  exit 1
fi

function batchNewBranchFromMaster() {
  options=
  if [[ "$1" == "-y" ]]; then
    options=$1
    shift 1
  fi
  filename=$1
  target_br=$2

  # 取当前目录
  base_dir=$(pwd)
  # 一次读取所有行到数组
  mapfile lines < "$filename"
  # 遍历数组
  for i in "${!lines[@]}";
  do
    line=${lines[$i]}
    # 过滤空行和#号开头的
    if [[ -z "$line" ]] || [[ ${line:0:1} == "#" ]]; then
      continue
    fi
    # 处理换行符
    line=$(echo "$line" | tr --delete '\n')
    line=$(echo "$line" | tr --delete '\r')
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
    # 打开文件夹
    cd "$base_dir/$project" || continue
    success_log "当前目录：$(pwd)"
    # 查看当前分支
    curr_br=$(git symbolic-ref --short -q HEAD)
    # 切换分支到master
    new_branch "$options" "$target_br"
    success_log "-----------------------"
  done
}

batchNewBranchFromMaster "$@"
