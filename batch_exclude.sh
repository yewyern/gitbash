#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 批量添加git exclude
# @author: 徐宙
# @date: 2024-07-16

# 获取脚本的全路径
script_path="$(realpath $0)"
# 提取脚本所在的目录
bash_dir="$(dirname $script_path)"
source "$bash_dir/task_common.sh"

flag=0
exclude_content=
projects=()
work_dir=$base_dir

function usage() {
    cat "$bash_dir/usage/batch_exclude.usage"
}


# exclude_with_project <project_dir>
function exclude_with_project() {
    project_dir=$1
    # 打开文件夹
    cd "$project_dir" || exit
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    if [ $(grep ^"$exclude_content"$ .git/info/exclude | wc -l) != 0 ]; then
        # 判断是否已存在
        success_log "已添加过exclude （$exclude_content）"
        grep ^"$exclude_content"$ .git/info/exclude
        return $SUCCESS
    fi
    # 提示是否添加exclude
    if [[ $flag == 0 ]]; then
        get_continue "是否添加exclude（$exclude_content）？(y/n)"
        if [ $? == $FAILED ]; then
            return $SUCCESS
        fi
    fi
    echo "$exclude_content" >> .git/info/exclude
    success_log "添加exclude （$exclude_content） 成功"
}

# batch_exclude
function batch_exclude() {
    for i in "${!projects[@]}";
    do
        project=${projects[$i]}
        exclude_with_project $work_dir"/"$project
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    params=`getopt -o hy -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    if [ $# -lt 1 ]; then
        usage
        exit 1
    fi
    exclude_content=$1
    if [ $# -lt 2 ]; then
        projects=($(get_directories))
    else
        # 获取任务信息
        get_task $2
        work_dir=${task_info["work_dir"]}
        projects=(${task_projects[*]})
    fi
    # 批量创建分支
    batch_exclude
    exit 0
}

main "$@"

