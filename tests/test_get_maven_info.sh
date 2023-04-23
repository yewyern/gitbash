#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键切换分支
# @author: 徐宙
# @date: 2020-12-08

bash_dir=$(dirname "$0")
#base_dir=$(pwd)

source "$bash_dir/util.sh"
source "$bash_dir/config/maven.config"
maven_info=
maven_setting_env_file="$bash_dir/config/settings-dev.xml";
pom_file=pom.xml
tmp_file=get_maven_info_temp.xml

function execute_maven_goals() {
    "$JAVA_CMD_PATH" -classpath "$MAVEN_HOME/$MAVEN_CLASSPATH" \
            -Dclassworlds.conf=$MAVEN_HOME/bin/m2.conf \
            -Dmaven.home=$MAVEN_HOME \
            -Dmaven.multiModuleProjectDirectory=$multiModuleProjectDirectory \
            $MAVEN_MAIN_CLASS \
            -s "$maven_setting_env_file" \
            $@
}

function confirm_value() {
    ref=$1
    val=${!ref}
    echo "请确认$1($val):"
    read val
    if [ "$val" != "" ]; then
        set "$1" "$val"
    fi
    val=${!ref}
    echo $val
}

function confirm_maven_info() {
    confirm_value maven_info
}

function get_maven_info() {
    multiModuleProjectDirectory=$(basename "$(pwd)")
    execute_maven_goals dependency:list -N -o | grep -C 1 "Building" > $tmp_file
#    cat $tmp_file
    maven_info=`sed -n '1p' $tmp_file | cut -d ' ' -f3 | awk -F: '{print $1,$2}'`
    maven_info="$maven_info "`sed -n '2p' $tmp_file | cut -d ' ' -f4`
    maven_info="$maven_info "`sed -n '3p' $tmp_file | cut -d ' ' -f3`
    echo $maven_info
    confirm_maven_info
    echo $maven_info
#    grep "<>" $tmp_file | cut -d ' ' -f4
#    grep -A 1 "<" temp.log | grep -A 1 ">"
    rm -f $tmp_file
#    grep -n "<parent>" $pom_file | sed
}

get_maven_info "$@"