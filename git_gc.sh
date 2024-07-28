#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 批量执行git gc
# @author: 徐宙
# @date: 2023-04-15

# 获取脚本的全路径
script_path="$(realpath $0)"
# 提取脚本所在的目录
bash_dir="$(dirname $script_path)"
base_dir=$(pwd)
source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"

projects=()
work_dir=$base_dir

function gc_with_project() {
    project_dir=$1
    # 打开文件夹
    cd "$project_dir" || return $FAILED
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    git gc
}

function batch_gc() {
    for i in "${!projects[@]}";
    do
        project=${projects[$i]}
        gc_with_project "$work_dir/$project"
        success_log "-----------------------"
        success_log
    done
}

function main() {
    if [ $# -lt 1 ]; then
        projects=($(git_directories))
    else
        get_task $1
        work_dir=${task_info["work_dir"]}
        projects=(${task_projects[*]})
    fi
    batch_gc
    exit 0
}

main "$@"