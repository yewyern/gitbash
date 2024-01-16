#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 批量更新脚本
# @author: 徐宙
# @date: 2020-12-08

# 获取脚本的全路径
script_path="$(realpath $0)"
# 提取脚本所在的目录
bash_dir="$(dirname $script_path)"
base_dir=$(pwd)
source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"

flag=0
projects=()
work_dir=$base_dir

function usage() {
    cat "$bash_dir/usage/batch_pull.usage"
}

function pull_with_project() {
    project_dir=$1
    # 打开文件夹
    cd "$project_dir" || return $FAILED
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    # 提示是否进行更新
    if [[ $flag == 0 ]]; then
        get_continue "是否进行更新？(y/n)"
        toContinue=$?
        if [ $toContinue == $FAILED ]; then
            return $SUCCESS
        fi
    fi
    git_pull
}

function batch_pull() {
    for i in "${!projects[@]}";
    do
        project=${projects[$i]}
        pull_with_project "$work_dir/$project"
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    parameters=`getopt -o hy -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$parameters"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    if [ $# -lt 1 ]; then
        projects=($(get_directories))
    else
        get_task $1
        work_dir=${task_info["work_dir"]}
        projects=(${task_projects[*]})
    fi
    batch_pull
    exit 0
}

main "$@"