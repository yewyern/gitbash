#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 批量删除已合并的分支，支持同步删除远程分支
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
user=
projects=()

function usage() {
    cat "$bash_dir/usage/batch_clear_merged_branch.usage"
}

# delete_branch_with_project <project_dir> <user>
function clear_merged_branch_with_project() {
    project_dir=$1
    # 打开文件夹
    cd "$project_dir" || exit
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    main_branch=$(git_main_branch)
    git_switch_branch $main_branch -y --pull_after
    git_merged_branch $user $main_branch
    merged_branches=($(git_merged_branch $user))
    for merged_branch in "${merged_branches[@]}"; do
        if [[ "$merged_branch" == '' ]]; then
            continue
        fi
        if [ $flag == 1 ]; then
            git_delete_branch $merged_branch -y
        else
            git_delete_branch $merged_branch
        fi
    done
}

# batch_clear_merged_branch <user>
function batch_clear_merged_branch() {
    for i in "${!projects[@]}";
    do
        project=${projects[$i]}
        project_dir="$work_dir/$project"
        clear_merged_branch_with_project "$project_dir" "$user"
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    params=`getopt -o hyu: --long from-branch: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            -u) user=$2; shift 2 ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    if [ "$user" == '' ]; then
        user=$(git config --get user.name)
    fi
    if [ "$user" == '' ]; then
        error_log "用户名：$user 为空"
        error_log "请传入-u参数指定"
        error_log "或使用 git config --global user.name \"Your Name\"进行全局配置"
        error_log "或使用 git config user.name \"Your Name\"进行单个项目配置"
        exit 0
    fi
    if [ $# -lt 1 ]; then
        work_dir=$(pwd)
        projects=($(get_directories))
    else
        get_task $1
        work_dir=${task_info["work_dir"]}
        projects=(${task_projects[*]})
    fi
    # 批量创建分支
    batch_clear_merged_branch $user
    exit 0
}

main "$@"

