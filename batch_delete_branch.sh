#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 批量删除分支，支持同步删除远程分支
# @author: 徐宙
# @date: 2024-07-02

# 获取脚本的全路径
script_path="$(realpath $0)"
# 提取脚本所在的目录
bash_dir="$(dirname $script_path)"
#base_dir=$(pwd)
source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"

flag=0
env=
to_del_branch=
projects=()

function usage() {
    cat "$bash_dir/usage/batch_delete_branch.usage"
}

# delete_branch_with_project <project_dir> <real_to_del_branch>
function delete_branch_with_project() {
    project_dir=$1
    real_to_del_branch=$2
    # 打开文件夹
    cd "$project_dir" || exit
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    # 创建分支
    if [ $flag == 1 ]; then
        git_delete_branch $real_to_del_branch -y
    else
        git_delete_branch $real_to_del_branch
    fi
}

# batch_delete_branch
function batch_delete_branch() {
    for i in "${!projects[@]}";
    do
        project=${projects[$i]}
        real_to_del_branch=$to_del_branch
        if [[ "$real_to_del_branch" == '' ]]; then
            real_to_del_branch=`get_branch $env $project`
            if [ $? == $FAILED ]; then
                # 获取分支有异常，跳过
                error_log $real_to_del_branch
                continue
            fi
        fi
        delete_branch_with_project $work_dir"/"$project $real_to_del_branch
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    params=`getopt -o hye:b: --long from-branch: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            -e) env=$2; shift 2 ;;
            -b) to_del_branch=$2; shift 2 ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    if [ $# -lt 1 ]; then
        usage
        exit 1
    fi
    # 获取任务信息
    get_task $1
    projects=(${task_projects[*]})
    work_dir=${task_info["work_dir"]}
    if [[ "$to_del_branch" == '' ]]; then
        to_del_branch=`get_branch $env`
        if [ $? == $FAILED ]; then
            # 获取分支有异常，推出
            error_log $to_del_branch
            exit 1
        fi
    fi
    if [ "$to_del_branch" == 'master' ]; then
        error_log "master分支不能删除"
        exit 1
    fi
    # 批量创建分支
    batch_delete_branch
    exit 0
}

main "$@"

