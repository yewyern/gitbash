#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 批量新建分支
# @author: 徐宙
# @date: 2020-12-08

# 获取脚本的全路径
script_path="$(realpath $0)"
# 提取脚本所在的目录
bash_dir="$(dirname $script_path)"
#base_dir=$(pwd)
source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"

task_id=
flag=0
from_branch=master
new_branch=
from_env=
env=
projects=()

function usage() {
    cat "$bash_dir/usage/batch_new_branch.usage"
}

function new_branch_with_project() {
    project_dir=$1
    from_br=$2
    to_br=$3
    # 打开文件夹
    cd "$project_dir" || exit
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    # 创建分支
    if [ $flag == 1 ]; then
        git_create_branch $from_br $to_br -y
    else
        git_create_branch $from_br $to_br
    fi
}

function batch_new_branch() {
    for i in "${!projects[@]}";
    do
        project=${projects[$i]}
        real_from_branch=$from_branch
        if [[ "$real_from_branch" == '' ]]; then
            real_from_branch=`get_branch $from_env $project`
            if [ $? == $FAILED ]; then
                # 获取分支有异常，跳过
                list_task $task_id
                error_log $real_from_branch
                exit 1
            fi
        fi
        real_new_branch=$new_branch
        if [[ "$real_new_branch" == '' ]]; then
            real_new_branch=`get_branch $env $project`
            if [ $? == $FAILED ]; then
                # 获取分支有异常，跳过
                list_task $task_id
                error_log $real_new_branch
                exit 1
            fi
        fi
        new_branch_with_project $work_dir"/"$project $real_from_branch $real_new_branch
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    params=`getopt -o hye:E:f:b: --long from-env:,from-branch: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            -e) env=$2; shift 2 ;;
            -E | --from-env) from_env=$2; shift 2 ;;
            -f | --from-branch) from_branch=$2; shift 2 ;;
            -b) new_branch=$2; shift 2 ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    if [ $# -lt 1 ]; then
        usage
        exit 1
    fi
    task_id=$1
    # 获取任务信息
    get_task $task_id
    projects=(${task_projects[*]})
    work_dir=${task_info["work_dir"]}
    # 获取任务级别新分支
    if [[ "$new_branch" == '' ]]; then
        new_branch=`get_branch $env`
        if [ $? == $FAILED ]; then
            # 获取分支有异常，推出
            list_task $task_id
            error_log $new_branch
            exit 1
        fi
    fi
    # 获取任务级别源分支
    if [[ "$from_branch" == '' ]]; then
        from_branch=`get_branch $from_env`
        if [ $? == $FAILED ]; then
            # 获取分支有异常，推出
            list_task $task_id
            error_log $from_branch
            exit 1
        fi
    fi
    # 批量创建分支
    batch_new_branch
    exit 0
}

main "$@"

