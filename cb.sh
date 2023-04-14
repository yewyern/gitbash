#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键切换分支
# @author: 徐宙
# @date: 2020-12-08

bash_dir=$(dirname "$0")
base_dir=$(pwd)
source $bash_dir"/util.sh"

flag=false
declare -A task_info
projects=()
task_branch=
env=
branch_env_file=

function usage() {
    cat $bash_dir"/usage/cb.usage"
}

# 0 - 分支不存在
# 1 - 本地分支，无远程
# 2 - 远程分支
function get_branch_type() {
  # 判断远程分支是否存在
  if [ $(git ls-remote --heads $(git remote | head -1) "$1" | cut -d$'\t' -f2 | sed 's,refs/heads/,,' | grep ^"$1"$ | wc -l) != 0 ]; then
    echo 2
  # 判断只存在于本地，没有远程的分支
  elif [ -z "$(git branch --list $1)" ]; then
    echo 0
  else
    echo 1
  fi
}

function get_continue() {
  echo "$@"
  # read不能在管道里使用
  read toContinue
  if [[ "Y" == "$toContinue" || "y" == "$toContinue" ]]; then
    return 1
  fi
  return 0
}

function switch_branch() {
  # 查看当前分支
  curr_br=$(git symbolic-ref --short -q HEAD)
  target_br=$1
  success_log "当前分支：$curr_br"
  success_log "目标分支：$target_br"

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

  needStash=0
  # 如果有内容修改
  if [[ -n "$(git status --porcelain)" ]]; then
    error_log "** 有内容修改未提交"
    error_log "** 请确认是否需要切换，如确认切换，将使用git stash保存空间之后，再切换分支"
    error_log "** 反之，请确认提交，或保存之后，再切换分支"
    needStash=1
  fi

  # 提示是否需要切换
  if [[ !$flag || $needStash = 1 ]]; then
    get_continue "是否进行切换？(y/n)"
    toContinue=$?
    if [ $toContinue = 0 ]; then
        return 1
    fi
  fi

  if [ $needStash = 1 ]; then
    git stash
    if [[ -n "$(git status --porcelain)" ]]; then
      error_log "** 使用git stash保存空间失败，无法切换分支"
      return 0
    fi
  fi

  git fetch
  success_log "切换分支到：$target_br"
  branch_type=$(get_branch_type "$target_br")
  if [[ $branch_type = 0 ]]; then
    error_log "** 分支不存在，请检查是否添加过分支"
    return 0
  fi
  git checkout "$target_br"
  curr_br=$(git symbolic-ref --short -q HEAD)
  if [[ "$curr_br" != "$target_br" ]]; then
    error_log "** 切换分支失败，当前分支：$curr_br"
    return 0
  fi
  success_log "切换成功，当前分支：$curr_br"
  if [[ $branch_type = 2 ]]; then
    # 更新远程分支到本地
    git pull --rebase
  fi

  if [ $needStash = 1 ]; then
    get_continue "有保存的工作空间，是否需要还原？(y/n)"
    toContinue=$?
    if [ $toContinue = 0 ]; then
        return 1
    fi
    git stash apply
  fi
  return 1
}


function switch_branch_with_project() {
    project_dir=$1
    target_br=$2
    # 打开文件夹
    cd "$project_dir" || exit
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    # 切换分支
    switch_branch $target_br
    success_log "-----------------------"
    success_log
}

function batch_switch_branch() {
    for i in "${!projects[@]}";
    do
        project=${projects[$i]}
        work_dir=${task_info["work_dir"]}
        if [[ $task_branch == '' ]]; then
            if [ $env != '' ]; then
                task_branch=`get_value_by_key "$branch_env_file" "$project" " "`
            else
                task_branch=${task_info["task_branch"]}
            fi
        fi
        switch_branch_with_project $work_dir"/"$project $task_branch
    done
}

function get_task() {
    # 解析taskInfo
    OLD_IFS=$IFS
    IFS=$'\n'
    lines=(`$bash_dir/task_manage.sh show $task_id`)
    len=${#lines[@]}
    if [ $len != 2 ]; then
        error_log "未找到对应的任务，请检查任务配置"
        exit 1
    fi
    IFS='|'
    read -r -a head <<< "${lines[0]}"
    read -r -a data <<< "${lines[1]}"
    for i in "${!head[@]}";
    do
        key=`trim ${head[$i]}`
        val=`trim ${data[$i]}`
        # 字符串拼接可以放到双引号内，也可以放到双引号外，放到双引号内可能出现问题，丢失部分字符，原因未知
        task_info["$key"]="$val"
    done
    IFS=','
    projects=(${task_info["projects"]})
    IFS=$OLD_IFS
}

# 解析参数
parameters=`getopt -o hyb:e: -n "$0" -- "$@"`
[ $? != 0 ] && exit 1
eval set -- "$parameters"
while true ; do
    case "$1" in
        -h) usage; exit 0 ;;
        -y) flag=true; shift ;;
        -b) task_branch=$2; shift 2 ;;
        -e) env=$2; branch_env_file=$bash_dir"/config/branch_"$env".txt"; shift 2 ;;
        --) shift; break ;;
        *) usage; exit 1 ;;
    esac
done

if [ $# -lt 1 ]; then
    usage
    exit 1
else
    task_id=$1
    get_task
    batch_switch_branch
    exit 0
fi

