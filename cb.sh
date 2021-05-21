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

# 0 - 分支不存在
# 1 - 本地分支，无远程
# 2 - 远程分支
function get_branch_type() {
  # 判断远程分支是否存在
  if [ `git ls-remote --heads $(git remote | head -1) "$1" | cut -d$'\t' -f2 | sed 's,refs/heads/,,' | grep ^"$1"$ | wc -l` != 0 ]; then
    echo 2
  # 判断只存在于本地，没有远程的分支
  elif [ -z "%(git branch --list $1)" ]; then
    echo 0
  else
    echo 1
  fi
}


function swith_branch() {
  # 查看当前分支
  curr_br=`git symbolic-ref --short -q HEAD`
  target_br=$1
  # 如果分支相同无需切换
  if [ "$curr_br" = "$target_br" ]; then
    success_log "分支相同，无需切换"
    return 1
  fi
  # 如果有内容修改
  if [ -n "$(git status --porcelain)" ]; then
    error_log "** 有内容修改未提交，无法切换分支"
    error_log "** 请确认提交，或使用git stash保存空间之后，再切换分支"
    return 0
  fi
  git fetch
  success_log "切换分支到：$target_br"
  branch_type=`get_branch_type $target_br`
  if [ $branch_type = 0 ]; then
    error_log "** 分支不存在，请检查是否添加过分支"
    return 0
  fi
  git checkout $target_br
  curr_br=`git symbolic-ref --short -q HEAD`
  if [ "$curr_br" != "$target_br" ]; then
    error_log "** 切换分支失败，当前分支：$curr_br"
    return 0
  fi
  success_log "切换成功，当前分支：$curr_br"
  if [ $branch_type = 2 ]; then
    # 更新远程分支到本地
    git pull --rebase
  fi
  return 1
}

if [ $# -lt 1 ]; then
  error_log "Usage: cb.sh filename [branch_index]"
  error_log "example: cb.sh brach_list.txt"
  error_log "example: cb.sh brach_list.txt 2"
  error_log "brach_list.txt like this: "
  error_log "test1	dev	test master"
  error_log "test2	dev	test master"
  exit 1
fi

filename=$1
branch_index=$2
if [ -z "$branch_index" ]; then
  branch_index=1
fi
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
  target_br=${arr[$branch_index]}
  # 打开文件夹
  cd $base_dir/$project
  success_log "当前目录：`pwd`"
  # 查看当前分支
  curr_br=`git symbolic-ref --short -q HEAD`
  success_log "当前分支：$curr_br"
  success_log "目标分支：$target_br"
  # 切换分支
  swith_branch $target_br
  success_log "-----------------------"
done < $filename