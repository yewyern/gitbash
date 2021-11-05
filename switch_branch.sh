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

if [ $# -lt 1 ] ; then
	echo "Usage: switch_branch.sh to_branch_name [-y]"
	echo "example: switch_branch.sh dev -y"
	exit 1
fi

function switch_branch() {
  options=
  if [[ "$1" == "-y" ]]; then
    options=$1
    shift 1
  fi

  # 查看当前分支
  curr_br=`git symbolic-ref --short -q HEAD`
  target_br=$1
  # 分支为空，不切换
  if [[ -z "$target_br" ]]; then
    success_log "分支为空，不切换"
    return 1
  fi
  # 如果分支相同无需切换
  if [[ "$curr_br" = "$target_br" ]]; then
    success_log "分支相同，无需切换"
    return 1
  fi

  # 提示是否需要切换
  if [[ "$options" != "-y" ]]; then
    echo -n "是否进行切换？(y/n)"
    read toContinue
    if [[ "Y" != "$toContinue" && "y" != "$toContinue" ]]; then
      return 1
    fi
  fi

  # 如果有内容修改
  if [[ -n "$(git status --porcelain)" ]]; then
    error_log "** 有内容修改未提交，无法切换分支"
    error_log "** 请确认提交，或使用git stash保存空间之后，再切换分支"
    return 0
  fi
  git fetch
  success_log "切换分支到：$target_br"
  branch_type=$(sh "$BASH_HOME/get_branch_type.sh" "$target_br")
  if [[ $branch_type = 0 ]]; then
    error_log "** 分支不存在，请检查是否添加过分支"
    return 0
  fi
  git checkout $target_br
  curr_br=`git symbolic-ref --short -q HEAD`
  if [[ "$curr_br" != "$target_br" ]]; then
    error_log "** 切换分支失败，当前分支：$curr_br"
    return 0
  fi
  success_log "切换成功，当前分支：$curr_br"
  if [[ $branch_type = 2 ]]; then
    # 更新远程分支到本地
    git pull --rebase
  fi
  return 1
}

switch_branch "$@"
exit $?