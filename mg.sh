#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键合并分支
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

function merge_branch() {
  from_br=$1
  to_br=$2
  success_log "源分支：$from_br"
  success_log "目标分支：$to_br"
  # 如果分支一样的无需合并
  if [ "$from_br" = "$to_br" ]; then
    success_log "分支相同无需合并"
    return 1
  fi
  # 判断是否存在未提交的文件
  if [ -n "$(git status --porcelain)" ]; then
    error_log "** 有内容修改未提交，无法切换分支"
    error_log "** 请确认提交，或使用git stash保存空间之后，再切换分支"
    return 0
  fi

  # 提示是否需要合并
  if [[ $no_prompt = 0 ]]; then
    echo -n "是否进行合并？(y/n)"
    read toContinue
    if [[ "$toContinue" != "y" ]]; then
      return 1
    fi
  fi

  # 拉取远程分支
  git fetch
  # 切换源分支
  swith_branch $from_br
  if [ $? = 0 ]; then
    return 0
  fi
  success_log "切换源分支成功，$from_br"
  # 切换目标分支
  swith_branch $to_br
  if [ $? = 0 ]; then
    return 0
  fi
  success_log "切换目标分支成功，$to_br"
  # 判断是否已经合并成功
  git merge-base --is-ancestor $from_br HEAD
  if [ $? = 0 ]; then
    success_log "分支已经合并无需再次合并"
    return 1
  fi
  git merge $from_br
  if [ -n "$(git status --porcelain)" ]; then
    error_log "合并$project分支$from_br到$to_br，存在冲突"
    return 0
  fi
  success_log "合并$project分支$from_br到$to_br成功"
  branch_type=`get_branch_type $to_br`
  if [ $branch_type = 2 ]; then
    git push
    success_log "已推送$project分支$to_br到远程"
  fi
  return 1
}

if [ $# -lt 1 ]; then
  error_log "Usage: mg.sh [-y] filename [from_branch_index to_branch_index]"
  error_log "example: mg.sh brach_list.txt"
  error_log "example: mg.sh brach_list.txt 1 2"
  error_log "example: mg.sh -y brach_list.txt 1 2"
  error_log "brach_list.txt like this: "
  error_log "test1  dev test master"
  error_log "test2  dev test master"
  exit 1
fi

no_prompt=0
if [[ "$1" == "-y" ]]; then
  #statements
  no_prompt=1
  shift 1
fi
filename=$1
from_branch_index=$2
to_branch_index=$3
if [ -z "$from_branch_index" ]; then
  from_branch_index=1
fi
to_branch_index=$3
if [ -z "$to_branch_index" ]; then
  to_branch_index=2
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
  # 合并的源分支
  from_br=${arr[$from_branch_index]}
  # 合并之后的目标分支
  to_br=${arr[$to_branch_index]}
  if [[ -z "$from_br" ]] || [[ -z "$to_br" ]]; then
    continue
  fi
  # 打开文件夹
  cd $base_dir/$project
  success_log "当前目录：`pwd`"
  merge_branch $from_br $to_br
  success_log "-----------------------"
done