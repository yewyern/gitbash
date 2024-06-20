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
branch_env_file=
from_branch=
to_branch=
from_env=
branch_from_env_file=

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
        if [ "$to_br" == '' ]; then
            if [ "$env" == 'dev' ]; then
                to_br=${task_info["release_branch"]}"."$username
            elif [ "$env" == 'release' ]; then
                to_br=${task_info["release_branch"]}
            elif [ "$env" != '' ]; then
                to_br=`get_value_by_key "$branch_env_file" "$project" 0 1`
            else
                to_br=$task_branch
            fi
        fi
        if [ "$from_br" == '' ]; then
            if [ "$from_env" == 'dev' ]; then
                from_br=${task_info["release_branch"]}"."$username
            elif [ "$from_env" == 'release' ]; then
                from_br=${task_info["release_branch"]}
            elif [ "$from_env" != '' ]; then
                from_br=`get_value_by_key "$branch_from_env_file" "$project" 0 1`
            else
                from_br=$task_branch
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
            -e) env=$2; branch_env_file=$bash_dir"/config/branch_"$env".txt"; shift 2 ;;
            -f | --from-branch) from_branch=$2; shift 2 ;;
            -t | --to-branch) to_branch=$2; shift 2 ;;
            -E | --from-env) from_env=$2; branch_from_env_file=$bash_dir"/config/branch_"$from_env".txt"; shift 2 ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    if [ $# -lt 1 ]; then
        usage
        exit 1
    else
        get_task $1
        batch_merge_branch
        exit 0
    fi
}

main "$@"

