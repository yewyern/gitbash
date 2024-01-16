#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 获取文件夹内所有git项目的remote url并生成文件remote.txt
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
projects=()
# 初始化结果文件
res_file=remote.txt
echo >$res_file

function usage() {
    cat "$bash_dir/usage/batch_pull.usage"
}

function get_remote_with_project() {
    project=$1
    # 打开文件夹
    cd "$base_dir/$project" || return $FAILED
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    # 查看当前分支
    remote_url=`git_get_remote`
    if [ $? != $SUCCESS ]; then
        return $FAILED
    fi
    if [ "$remote_url" == '' ]; then
        error_log "无远程仓库"
        return $FAILED
    fi
    echo "$remote_url"
    echo "$project $remote_url" >>"$base_dir/$res_file"
}

function batch_get_remote() {
    for i in "${!projects[@]}";
    do
        project=${projects[$i]}
        get_remote_with_project $project
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    parameters=`getopt -o hy -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$parameters"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    projects=($(get_directories))
    batch_get_remote
    exit 0
}

main "$@"