#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 批量删除分支，支持同步删除远程分支
# @author: 徐宙
# @date: 2020-12-08

# 获取脚本的全路径
script_path="$(realpath $0)"
# 提取脚本所在的目录
bash_dir="$(dirname $script_path)"
#base_dir=$(pwd)
source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"

flag=0
to_del_branch=
projects=()

function usage() {
    cat "$bash_dir/usage/batch_delete_branch.usage"
}

function delete_branch_with_project() {
    project_dir=$1
    # 打开文件夹
    cd "$project_dir" || exit
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    # 创建分支
    if [ $flag == 1 ]; then
        git_delete_branch $to_del_branch -y
    else
        git_delete_branch $to_del_branch
    fi
}

function batch_delete_branch() {
    for i in "${!projects[@]}";
    do
        project=${projects[$i]}
        delete_branch_with_project $work_dir"/"$project
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    params=`getopt -o hye:f:b: --long from-branch: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            -e) env=$2; branch_env_file=$bash_dir"/config/branch_"$env".txt"; shift 2 ;;
            -f | --from-branch) from_branch=$2; shift 2 ;;
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
        if [ "$env" == 'dev' ]; then
            to_del_branch=${task_info["release_branch"]}"."$username
        elif [ "$env" != '' ]; then
            to_del_branch=${task_info[$env"_branch"]}
            if [[ "$to_del_branch" == '' ]]; then
                to_del_branch=`get_value_by_key "$branch_env_file" "$project" 0 1`
            fi
        else
            to_del_branch=${task_info["task_branch"]}
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

