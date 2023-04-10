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

function pull() {
  target_br=$1
  branch_type=$2
  if [ $branch_type = 2 ]; then
    # 更新远程分支到本地
    git pull --rebase
  fi
}

function switch_branch() {
  # 查看当前分支
  curr_br=`git symbolic-ref --short -q HEAD`
  target_br=$1
  branch_type=`get_branch_type $target_br`
  if [ $branch_type = 0 ]; then
    error_log "** 分支不存在，请检查是否添加过分支"
    return 0
  fi
  # 如果分支相同无需切换
  if [ "$curr_br" = "$target_br" ]; then
    success_log "分支相同，无需切换"
    pull $target_br $branch_type
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
  pull $target_br $branch_type
  return 1
}

get_continue() {
  echo "$@"
  # read不能在管道里使用
  read toContinue
  if [[ "Y" == "$toContinue" || "y" == "$toContinue" ]]; then
    return 1
  fi
  return 0
}

merge_branch() {
  options=
  if [[ "$1" == "-y" ]]; then
    options=$1
    shift 1
  fi
  from_br=$1
  to_br=$2
  success_log "源分支：$from_br"
  success_log "目标分支：$to_br"
  # 分支为空，不合并
  if [[ -z "$from_br" ]]; then
    success_log "源分支为空，不合并"
    return 1
  fi
  if [[ -z "$to_br" ]]; then
    success_log "目标分支为空，不合并"
    return 1
  fi
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
  if [[ "$options" != "-y" ]]; then
    get_continue "是否进行合并？(y/n)"
    toContinue=$?
    if [ $toContinue = 0 ]; then
        return 1
    fi
  fi

  # 拉取远程分支
  git fetch
  # 切换源分支
  switch_branch $from_br
  if [ $? = 0 ]; then
    return 0
  fi
  success_log "切换源分支成功，$from_br"
  # 切换目标分支
  switch_branch $to_br
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
  project=$(basename "$(pwd)")
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

merge_branch_with_project() {
  options=
  if [[ "$1" == "-y" ]]; then
    options=$1
    shift 1
  fi
  project_dir=$1
  from_br=$2
  to_br=$3
  # 打开文件夹
  cd "$project_dir" || exit
  success_log "当前目录：`pwd`"
  # 合并分支
  merge_branch $options $from_br $to_br
}

function batch_merge_branch() {
  options=
  if [[ "$1" == "-y" ]]; then
    options=$1
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
    # $(($branch_index + 1)) branch_index 是从1开始的，但是前面有个project_name，所以branch_index要加1
    line=$(echo $line | awk -v base="$base_dir" -v opt="$options" -v N1="$(($from_branch_index + 1))" -v N2="$(($to_branch_index + 1))" '{print opt,base"/"$1,$N1,$N2}')
    merge_branch_with_project $line
    success_log "-----------------------"
    success_log
  done
}

batch_merge_branch "$@"