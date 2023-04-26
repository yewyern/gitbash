# 外部脚本需设置以下参数：
# deploy_mode                               发布模式，用于扩展时判断使用
# flag                                      0-提示是否发布
# MAVEN_HOME
# MAVEN_CLASSPATH
# MAVEN_MAIN_CLASS
# maven_setting_env_file
# multiModuleProjectDirectory
# maven_deploy_type jar jar_and_pom pom     发布类型
# group_id
# artifact_id
# artifact_version
# artifact_file                             jar文件绝对路径
# artifact_pom_file                         pom文件绝对路径
# repository_url                            私服上仓库的位置，打开nexus——>repositories菜单，可以看到该路径。
# repository_id                             服务器的id，在nexus的configuration可以看到。

# 注意在本shell自定义的方法不能与git_common.sh, task_common.sh, maven_batch_deploy.sh中的相同
function maven_deploy_extend() {
    if [ $deploy_mode == 1 ]; then
        maven_deploy_with_http
    fi
}

function maven_deploy_with_http() {
    # 发布jar包
    # 发布pom
    # 发布maven
    echo "使用http发布maven成功"
}