#!/usr/bin/env bash
#该命令使用`find`命令查找所有包含pom.xml文件的文件夹，并使用`-printf`选项将文件夹路径打印出来。接着使用管道符号 (`|`) 将文件夹路径传递到while循环中，循环读取每一个文件夹路径。
#
#在每个循环中，先进入该文件夹中执行以下操作：
#1. 使用mvn命令查询项目的groupId、artifactId和version，并使用grep命令过滤出需要的输出信息并打印出来。
#2. 执行`mvn package`命令进行Maven构建。
#3. 最后返回上层目录。
#`-Dexpression`选项可用于执行Maven表达式查询，这里用于查询项目的groupId、artifactId和version。使用 `grep` 命令过滤出需要的输出信息。
#注意：如果有多个maven项目的pom.xml都在同一个文件夹下，则该命令将重复执行多次，并分别进行Maven构建。

find . -name "pom.xml" -printf "%h\n" | while read dir; do \
    echo "Processing ${dir}"; \
    cd ${dir}; \
    mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate \
     -Dexpression=project.groupId | grep -v "\["; \
    mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate \
     -Dexpression=project.artifactId | grep -v "\["; \
    mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate \
     -Dexpression=project.version | grep -v "\["; \
    mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate \
        -Dexpression=project.packaging | grep -v "\[";
#    mvn package; \
    cd - >/dev/null; \
done





# 获取插件使用信息
mvn help:describe -Dplugin=org.apache.maven.plugins:maven-help-plugin:2.1.1 -Ddetail