#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键切换分支
# @author: 徐宙
# @date: 2020-12-08

bash_dir=$(dirname "$0")
base_dir=$(pwd)
flag=false
task_id=
task_branch=
env=
work_dir=
projects=

function usage() {
    cat $bash_dir"/usage/cb.usage"
}

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
  options=
  if [[ "$1" == "-y" ]]; then
    options=$1
    shift 1
  fi

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
  if [[ "$options" != "-y" || $needStash = 1 ]]; then
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
    options=
    if [[ "$1" == "-y" ]]; then
      options=$1
      shift 1
    fi
    project_dir=$1
    target_br=$2
    # 打开文件夹
    cd "$project_dir" || exit
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"

    # 切换分支
    switch_branch $options $target_br
}

function batch_switch_branch() {
    work_dir=`$bash_dir/task_manage.sh get $task_id work_dir`
    if [ $work_dir == '' ]; then
        error_log "未找到对应的任务，请检查任务配置"
    fi
    echo $work_dir
    if [[ $env == '' && $task_branch == '' ]]; then
        task_branch=`$bash_dir/task_manage.sh get $task_id task_branch`
    fi
    echo $task_branch
    projects=`$bash_dir/task_manage.sh get $task_id projects`
    echo $projects
    project_arr=(${projects//,/ })
    for var in ${project_arr[@]}
    do
        echo $var
    done

#  filename=$1
#  branch_index=$2
#  if [ -z "$branch_index" ]; then
#    branch_index=1
#  fi
#
#  # 去除以#开头的行和空行
#  OLD_IFS=$IFS
#  echo $OLD_IFS
#  IFS=$'\n'
#  lines=($(sed '/^#.*$/d' "$filename" | sed '/^$/d'))
#  IFS=$OLD_IFS
#  for i in "${!lines[@]}";
#  do
#    line=${lines[$i]}
#    # 字符串拼接可以放到双引号内，也可以放到双引号外，放到双引号内可能出现问题，丢失部分字符，原因未知
#    success_log "当前行："$line
#    # $(($branch_index + 1)) branch_index 是从1开始的，但是前面有个project_name，所以branch_index要加1
#    line=$(echo $line | awk -v base="$base_dir" -v opt="$options" -v N="$(($branch_index + 1))" '{print opt,base"/"$1,$N}')
#    switch_branch_with_project $line
#    success_log "-----------------------"
#    success_log
#  done
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
        -e) env=$2; shift 2 ;;
        --) shift; break ;;
        *) usage; exit 1 ;;
    esac
done

if [ $# -lt 1 ]; then
    usage
    exit 1
else
    task_id=$1
    batch_switch_branch
    exit 0
fi

