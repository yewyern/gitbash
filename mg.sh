#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键切换分支
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
task_branch=
env=
from_env=
from_branch=
to_branch=

function usage() {
    cat "$bash_dir/usage/mg.usage"
}

function merge_branch_with_project() {
    project_dir=$1
    from_br=$2
    to_br=$3
    # 打开文件夹
    cd "$project_dir" || exit
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    # 合并分支
    if [ $flag == 1 ]; then
        git_merge_branch $from_br $to_br -y
    else
        git_merge_branch $from_br $to_br
    fi
    success_log "-----------------------"
    success_log
}

function batch_merge_branch() {
    work_dir=${task_info["work_dir"]}
    task_branch=${task_info["task_branch"]}
    for i in "${!task_projects[@]}";
    do
        project=${task_projects[$i]}
        from_br=$from_branch
        to_br=$to_branch
        if [[ "$from_br" == '' ]]; then
            from_br=`get_branch $from_env $project`
            if [ $? == $FAILED ]; then
                # 获取分支有异常，跳过
                error_log $real_from_branch
                continue
            fi
        fi
        if [[ "$to_br" == '' ]]; then
            to_br=`get_branch $env $project`
            if [ $? == $FAILED ]; then
                # 获取分支有异常，跳过
                error_log $to_br
                continue
            fi
        fi
        merge_branch_with_project $work_dir"/"$project $from_br $to_br
    done
}

function main() {
    # 解析参数
    params=`getopt -o hye:f:t:E: --long from-branch:,to-branch:,from-env: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            -e) env=$2; shift 2 ;;
            -E | --from-env) from_env=$2; shift 2 ;;
            -f | --from-branch) to_branch=$2; shift 2 ;;
            -t | --to-branch) to_branch=$2; shift 2 ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    if [ $# -lt 1 ]; then
        usage
        exit 1
    else
        get_task $1
        # 获取任务级别目标分支
        if [[ "$to_branch" == '' ]]; then
            to_branch=`get_branch $env`
            if [ $? == $FAILED ]; then
                # 获取分支有异常，推出
                error_log $to_branch
                exit 1
            fi
        fi
        # 获取任务级别源分支
        if [[ "$from_branch" == '' ]]; then
            from_branch=`get_branch $from_env`
            if [ $? == $FAILED ]; then
                # 获取分支有异常，推出
                error_log $from_branch
                exit 1
            fi
        fi
        batch_merge_branch
        exit 0
    fi
}

main "$@"

