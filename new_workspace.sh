#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 使用当前目录的remote.txt，根据指定的项目列表，拉取所有指定的项目，已存在的不拉取
# @author: 徐宙
# @date: 2020-12-08

bash_dir=$(dirname "$0")
#base_dir=$(pwd)
source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"

remote_filename="$bash_dir/config/remote.txt"
flag=0
work_dir=
task_branch=

function usage() {
    cat "$bash_dir/usage/new_workspace.usage"
}

function switch_branch_with_project() {
    project_dir=$1
    target_br=$2
    # 打开文件夹
    cd "$project_dir" || return $FAILED
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    # 切换分支
    if [ $flag == 1 ]; then
        git_switch_branch $target_br -y --fetch_before --pull_after --stash prompt
    else
        git_switch_branch $target_br --fetch_before --pull_after --stash prompt
    fi
}

function add_project() {
    cd "$work_dir" || return $FAILED
    project=$1
    project_dir="$work_dir/$project"
    if [ ! -d "$project_dir" ]; then
        # 创建项目
        if [ $flag == 0 ]; then
            get_continue "是否进行拉取项目？(y/n)"
            toContinue=$?
            if [ $toContinue == $FAILED ]; then
                return $SUCCESS
            fi
        fi
        # 目标项目git url
        remote_url=$(get_value_by_key "$remote_filename" "$project" 0 1)
        if [[ -z "$remote_url" ]]; then
            error_log "未找到项目远程地址，请确认$remote_filename 是否正确！"
            return $FAILED
        fi
        success_log "当前目录：$(pwd)"
        git clone "$remote_url"
    fi
}

function batch_switch_branch() {
    work_dir=${task_info["work_dir"]}
    task_branch=${task_info["task_branch"]}
    if [ ! -d "$work_dir" ]; then
        success_log "创建工作目录：$work_dir"
        mkdir -p "$work_dir"
    fi
    cd "$work_dir" || exit
    for i in "${!task_projects[@]}"; do
        project=${task_projects[$i]}
        add_project $project
        switch_branch_with_project $work_dir"/"$project $task_branch
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    parameters=$(getopt -o hy -n "$0" -- "$@")
    [ $? != 0 ] && exit 1
    eval set -- "$parameters"
    while true; do
        case "$1" in
        -h)
            usage
            exit 0
            ;;
        -y)
            flag=1
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            usage
            exit 1
            ;;
        esac
    done

    if [ $# -lt 1 ]; then
        usage
        exit 1
    else
        get_task $1
        batch_switch_branch
        exit 0
    fi
}

main "$@"
