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
  elif [ -z "$(git branch --list $1)" ]; then
    echo 0
  else
    echo 1
  fi
}


function pull() {
  # 提示是否需要切换
  if [[ $no_prompt = 0 ]]; then
    echo -n "是否进行拉取？(y/n)"
    read toContinue
    if [[ "$toContinue" != "y" ]]; then
      return 1
    fi
  fi
  # 如果有内容修改
  if [ -n "$(git status --porcelain)" ]; then
    error_log "** 有内容修改未提交，无法拉取分支"
    error_log "** 请确认提交，或使用git stash保存空间之后，再拉取分支"
    return 0
  fi
  curr_br=$(git symbolic-ref --short -q HEAD)
  branch_type=$(get_branch_type "$curr_br")
  if [ $branch_type = 2 ]; then
    # 更新远程分支到本地
    git pull --rebase
  fi
  return 1
}

no_prompt=0
if [[ "$1" == "-y" ]]; then
  #statements
  no_prompt=1
  shift 1
fi
filename=$1
if [[ -z "$filename" ]]; then
  filename=temp.txt
  echo>$filename
  fileList=$(ls)
  for fn in $fileList
  do
    if test -d "$fn"
     then
        echo "$fn">>$filename
     fi
  done
fi
branch_index=$2
if [ -z "$branch_index" ]; then
  branch_index=1
fi
# 取当前目录
base_dir=$(pwd)
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
  line=$(echo $line | tr --delete '\n')
  line=$(echo $line | tr --delete '\r')
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
  cd $base_dir/$project
  success_log "当前目录：`pwd`"
  # 查看当前分支
  curr_br=`git symbolic-ref --short -q HEAD`
  success_log "当前分支：$curr_br"
  # 切换分支
  pull
  success_log "-----------------------"
done