#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键切换分支
# @author: 徐宙
# @date: 2020-12-08

bash_dir=$(dirname "$0")
#base_dir=$(pwd)
source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"

flag=0

function usage() {
    echo 1
}

function pull_with_project() {
    project_dir=$1
    # 打开文件夹
    cd "$project_dir" || return $FAILED
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    # 切换分支
    # 提示是否需要切换
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
    work_dir=${task_info["work_dir"]}
    for i in "${!task_projects[@]}";
    do
        project=${task_projects[$i]}
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
        usage
        exit 1
    else
        get_task $1
        batch_pull
        exit 0
    fi
}

main "$@"