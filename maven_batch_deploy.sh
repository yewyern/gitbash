#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键切换分支
# @author: 徐宙
# @date: 2020-12-08

bash_dir=$(dirname "$0")
#base_dir=$(pwd)
source "$bash_dir/config/maven.config"
source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"
source "$bash_dir/extend/maven_extend.sh"

flag=0
deploy_mode=0
work_dir=
task_branch=
env=
branch_env_file=
maven_setting_env_file=
multiModuleProjectDirectory=
maven_deploy_type=
group_id=
artifact_id=
artifact_version=
artifact_file=
artifact_pom_file=
repository_url=
repository_id=

function usage() {
    cat "$bash_dir/usage/maven_batch_deploy.usage"
}

function maven_package() {
    if [[ $flag == 0 ]]; then
        get_continue "是否需要编译？(y/n)"
        if [ $? = $FAIL ]; then
            # 跳过编译
            return $SUCCESS
        fi
    fi
    # maven 编译
    success_log "开始编译: "$multiModuleProjectDirectory
    "$JAVA_CMD_PATH" -classpath "$MAVEN_HOME/$MAVEN_CLASSPATH" \
        -Dclassworlds.conf=$MAVEN_HOME/bin/m2.conf \
        -Dmaven.home=$MAVEN_HOME \
        -Dmaven.multiModuleProjectDirectory=$multiModuleProjectDirectory \
        $MAVEN_MAIN_CLASS \
        -s "$maven_setting_env_file" \
        --update-snapshots clean -DskipTests package
    if [ $? = $SUCCESS ]; then
        success_log "编译成功"
        return $SUCCESS
    else
        error_log "编译失败"
        return $FAIL
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
    "$JAVA_CMD_PATH" -classpath "$MAVEN_HOME/$MAVEN_CLASSPATH" \
        -Dclassworlds.conf=$MAVEN_HOME/bin/m2.conf \
        -Dmaven.home=$MAVEN_HOME \
        -Dmaven.multiModuleProjectDirectory=$multiModuleProjectDirectory \
        $MAVEN_MAIN_CLASS \
        -s "$maven_setting_env_file" \
        deploy:deploy-file \
        $maven_deploy_args
    return $?
}

function maven_deploy() {
    if [[ $flag == 0 ]]; then
        get_continue "是否需要发布？(y/n)"
        if [ $? = $FAIL ]; then
            # 跳过编译
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
    if [ $? = $SUCCESS ]; then
        success_log "发布失败"
        return $SUCCESS
    else
        error_log "发布失败"
        return $FAIL
    fi
}

function maven_deploy_with_project() {
    multiModuleProjectDirectory=$1
    maven_package
    maven_deploy
}

function switch_branch_with_project() {
    project=$1
    target_br=$2
    # 打开文件夹
    cd "$work_dir/$project_dir" || exit
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
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
        if [[ $task_branch == '' ]]; then
            task_branch=`get_value_by_key "$branch_env_file" "$project" 0 1`
            if [ $task_branch == '' ]; then
                error_log "要编译的分支不能为空"
                exit 1
            fi
        fi
        # 切换到目标分支
        switch_branch_with_project $project $task_branch
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
            -b) task_branch=$2; shift 2 ;;
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
        maven_setting_env_file="$bash_dir/config/settings_$env.xml";
        get_task $1
        work_dir=${task_info["work_dir"]}
        if [[ $task_branch == '' ]]; then
            task_branch=${task_info["task_branch"]}
        fi
        batch_deploy_maven
        exit 0
    fi
}

main "$@"