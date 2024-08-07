#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 使用当前目录的remote.txt，根据指定的项目列表，拉取所有指定的项目，已存在的不拉取
# @author: 徐宙
# @date: 2023-04-15

# 获取脚本的全路径
script_path="$(realpath $0)"
# 提取脚本所在的目录
bash_dir="$(dirname $script_path)"
#base_dir=$(pwd)
source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"

task_mode=1
flag=0
remote_file=
work_dir=
task_branch=
projects=()

function usage() {
    cat "$bash_dir/usage/new_workspace.usage"
}

function switch_or_create_branch_with_project() {
    project_dir=$1
    target_br=$2
    # 打开文件夹
    cd "$project_dir" || return $FAILED
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"

    branch_type=$(git_branch_type "$target_br")
    # 如果分支存在，直接切换分支
    if [[ $branch_type != 0 ]]; then
        # 切换分支
        if [ $flag == 1 ]; then
            git_switch_branch $target_br -y --fetch_before --pull_after --stash prompt
        else
            git_switch_branch $target_br --fetch_before --pull_after --stash prompt
        fi
        return $SUCCESS
    fi
    # 分支不存在，从master创建分支
    error_log "分支不存在：$target_br，需要进行创建"
    if [ $flag == 1 ]; then
        git_create_branch master $target_br -y
    else
        git_create_branch master $target_br
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
        remote_url=$(get_value_by_key "$remote_file" "$project" 0 1)
        if [[ -z "$remote_url" ]]; then
            error_log "未找到项目远程地址，请确认$remote_file 是否正确！"
            return $FAILED
        fi
        success_log "当前目录：$(pwd)"
        git clone "$remote_url"
        return $?
    fi
    success_log "已存在项目，不拉取"
}

function new_workspace() {
    if [ ! -d "$work_dir" ]; then
        success_log "创建工作目录：$work_dir"
        mkdir -p "$work_dir"
    fi
    cd "$work_dir" || exit
    for i in "${!projects[@]}"; do
        project=${projects[$i]}
        success_log "当前项目："$project
        add_project $project
        [[ $? == $SUCCESS && "$task_branch" != '' ]] && switch_or_create_branch_with_project "$work_dir/$project" "$task_branch"
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    params=`getopt -o hynr:w: --long remote-file:,work-dir: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            -n) task_mode=0; shift ;;
            -r | --remote-file) remote_file=$2; shift 2 ;;
            -w | --work-dir) work_dir=$2; shift 2 ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    if [ $task_mode == 1 ]; then
        # 使用任务模式
        if [ $# -lt 1 ]; then
            usage
            exit 1
        fi
        get_task $1
        if [ "$work_dir" == '' ]; then
            work_dir=${task_info["work_dir"]}
        fi
        if [ "$remote_file" == '' ]; then
            remote_file=${task_info["remote_file"]}
        fi
        task_branch=${task_info["task_br"]}
        projects=(${task_projects[*]})
    fi
    if [ "$work_dir" == '' ]; then
        usage
        exit 1
    fi
    # remote_file 默认使用remote.txt
    if [ "$remote_file" == '' ]; then
        remote_file="remote.txt"
    fi

    work_dir=`realpath "$work_dir"`
    remote_file=`get_real_config_path "$remote_file" "$work_dir"`
    if [ $? == $FAILED ]; then
        # 获取远程配置异常，退出
        error_log $remote_file
        exit 1
    fi

    if [ $task_mode != 1 ]; then
        # 非任务模式
        projects=($(get_value_by_index "$remote_file" 0))
    fi

    new_workspace
    exit 0
}

main "$@"
