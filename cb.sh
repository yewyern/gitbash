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
#echo $base_dir
#base_dir=$(pwd)
source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"

flag=0
task_branch=
env=
work_dir=

function usage() {
    cat "$bash_dir/usage/cb.usage"
}

function switch_branch_with_project() {
    project_dir=$1
    target_br=$2
    # 打开文件夹
    cd "$project_dir" || exit
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    # 切换分支
    if [ $flag == 1 ]; then
        git_switch_branch $target_br -y --fetch_before --pull_after --stash prompt
    else
        git_switch_branch $target_br --fetch_before --pull_after --stash prompt
    fi
}

function batch_switch_branch() {
    if [ "$work_dir" == "" ]; then
        work_dir=${task_info["work_dir"]}
    fi
    work_dir=`realpath "$work_dir"`
    for i in "${!task_projects[@]}";
    do
        project=${task_projects[$i]}
        real_task_branch=$task_branch
        if [[ "$real_task_branch" == '' ]]; then
            real_task_branch=`get_branch $env $project`
            if [ $? == $FAILED ]; then
                # 获取分支有异常，跳过
                error_log $real_task_branch
                continue
            fi
        fi
        switch_branch_with_project $work_dir"/"$project $real_task_branch
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    parameters=`getopt -o hyb:e:w: --long work-dir: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$parameters"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            -b) task_branch=$2; shift 2 ;;
            -e) env=$2; shift 2 ;;
            -w | --work-dir) work_dir=$2; shift 2 ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    if [ $# -lt 1 ]; then
        usage
        exit 1
    else
        get_task $1
        # 获取任务级别新分支
        if [[ "$task_branch" == '' ]]; then
            task_branch=`get_branch $env`
            if [ $? == $FAILED ]; then
                # 获取分支有异常，推出
                error_log $task_branch
                exit 1
            fi
        fi
        batch_switch_branch
        exit 0
    fi
}

main "$@"