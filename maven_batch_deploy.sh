#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键切换分支
# @author: 徐宙
# @date: 2020-12-08

bash_dir=$(dirname "$0")
#base_dir=$(pwd)
flag=0
deploy_mode=0
work_dir=
work_branch=
env=
branch_env_file=
maven_setting_env_file=
maven_deploy_type=
group_id=
artifact_id=
artifact_version=
artifact_file=
artifact_pom_file=
repository_url=
repository_id=

source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"
source "$bash_dir/extend/maven_extend.sh"
source "$bash_dir/config/maven.config"

function usage() {
    cat "$bash_dir/usage/maven_batch_deploy.usage"
}

function execute_maven_goals() {
    multiModuleProjectDirectory=$(basename "$(pwd)")
    "$JAVA_CMD_PATH" -classpath "$MAVEN_HOME/$MAVEN_CLASSPATH" \
            -Dclassworlds.conf=$MAVEN_HOME/bin/m2.conf \
            -Dmaven.home=$MAVEN_HOME \
            -Dmaven.multiModuleProjectDirectory=$multiModuleProjectDirectory \
            $MAVEN_MAIN_CLASS \
            -s "$maven_setting_env_file" \
            $@
}

function set_maven_info() {
    group_id=$1
    artifact_id=$2
    artifact_version=$3
    maven_deploy_type=$4
    if [ "$maven_deploy_type" == "jar" ]; then
        maven_deploy_type=jar_and_pom
    fi
}

function get_maven_info() {
    tmp_file=get_maven_info_temp.xml
    execute_maven_goals dependency:list -N -o | grep -C 1 "Building" > $tmp_file
    maven_info=`sed -n '1p' $tmp_file | cut -d ' ' -f3 | awk -F: '{print $1,$2}'`
    maven_info="$maven_info "`sed -n '2p' $tmp_file | cut -d ' ' -f4`
    maven_info="$maven_info "`sed -n '3p' $tmp_file | cut -d ' ' -f3`
    set_maven_info $maven_info
    rm -f $tmp_file
}

function maven_package() {
    if [[ $flag == 0 ]]; then
        get_continue "是否需要编译？(y/n)"
        if [ $? != $SUCCESS ]; then
            # 跳过编译
            return $SUCCESS
        fi
    fi
    # maven 编译
    get_maven_info
    success_log "开始编译: ["$group_id":"$artifact_id":"$artifact_version"]"
    execute_maven_goals --update-snapshots -N -o clean -DskipTests package
    if [ $? != $SUCCESS ]; then
        error_log "编译失败"
        return $FAILED
    else
        success_log "编译成功"
        return $SUCCESS
    fi
}

function maven_deploy_default() {
    # maven 发布
    maven_deploy_args="-DgroupId=$group_id -DartifactId=$artifact_id -Dversion=$artifact_version"
    if [ "$maven_deploy_type" == "jar" ]; then
        maven_deploy_args="$maven_deploy_args -Dpackaging=jar -Dfile=$artifact_file"
    elif [ "$maven_deploy_type" == "jar_and_pom" ]; then
        maven_deploy_args="$maven_deploy_args -Dpackaging=jar -Dfile=$artifact_file -DpomFile=$artifact_pom_file"
    elif [ "$maven_deploy_type" == "pom" ]; then
        maven_deploy_args="$maven_deploy_args -Dpackaging=pom -DpomFile=$artifact_pom_file"
    else
        error_log "发布失败, maven_deploy_type 只支持：jar jar_and_pom pom 3种"
        exit 1
    fi
    maven_deploy_args="$maven_deploy_args -Durl=$repository_url -DrepositoryId=$repository_id"
    execute_maven_goals deploy:deploy-file $maven_deploy_args -N -o
    return $?
}

function maven_deploy() {
    if [[ $flag == 0 ]]; then
        get_continue "是否需要发布？(y/n)"
        if [ $? != $SUCCESS ]; then
            # 跳过发布
            return $SUCCESS
        fi
    fi
    if [ $deploy_mode == 0 ]; then
        # 默认使用maven 命令发布
        maven_deploy_default
    else
        # 可用于扩展
        maven_deploy_extend
    fi
    if [ $? != $SUCCESS ]; then
        success_log "发布失败"
        return $SUCCESS
    else
        error_log "发布失败"
        return $FAILED
    fi
}

function maven_deploy_with_project() {
    maven_package
    if [ $? != $SUCCESS ]; then
        return $FAILED
    fi
    maven_deploy
}

function switch_branch_with_project() {
    project=$1
    target_br=$2
    # 切换分支
    if [ $flag == 1 ]; then
        git_switch_branch $target_br -y --fetch_before --pull_after --stash prompt
    else
        git_switch_branch $target_br --fetch_before --pull_after --stash prompt
    fi
}

function batch_deploy_maven() {
    for i in "${!task_projects[@]}";
    do
        project=${task_projects[$i]}
        if [[ "$work_branch" == "" ]]; then
            work_branch=`get_value_by_key "$branch_env_file" "$project" 0 1`
            if [ "$work_branch" == "" ]; then
                error_log "要编译的分支不能为空"
                exit 1
            fi
        fi
        # 打开文件夹
        cd "$work_dir/$project" || exit
        curr_dir=$(pwd)
        success_log "当前目录：$curr_dir"
        if [[ $flag == 0 ]]; then
            get_continue "是否需要发布？(y/n)"
            if [ $? != $SUCCESS ]; then
                # 跳过发布
                continue
            fi
        fi
        # 切换到目标分支
        switch_branch_with_project $project $work_branch
        # maven编译
        maven_deploy_with_project $project
        success_log "-----------------------"
        success_log
    done
}

function main() {
    if [[ "$JAVA_CMD_PATH" == "" || "$MAVEN_HOME" == "" ]]; then
        usage
        exit 1
    fi
    # 解析参数
    parameters=`getopt -o hyb: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$parameters"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            -b) work_branch=$2; shift 2 ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    if [ $# -lt 2 ]; then
        usage
        exit 1
    else
        env=$2
        branch_env_file="$bash_dir/config/branch_$env.txt";
        maven_setting_env_file="$bash_dir/config/settings-$env.xml";
        get_task $1
        work_dir=${task_info["work_dir"]}
        batch_deploy_maven
        exit 0
    fi
}

main "$@"