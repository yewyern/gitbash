SUCCESS=0
FAILED=1

function success_log() {
    echo -e "\033[32m $* \033[0m"
}

function error_log() {
    echo -e "\033[31m $* \033[0m"
}

function trim() {
    echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function get_continue() {
    echo "$@"
    # read不能在管道里使用
    read toContinue
    if [[ "Y" == "$toContinue" || "y" == "$toContinue" ]]; then
        return $SUCCESS
    fi
    return $FAILED
}

# 获取当前目录下所有文件夹
# usage: get_directories
function get_directories() {
    # 在 Bash 中，可以使用如下命令将当前目录下所有目录名保存到一个数组中：
#    dirs=( */ )
    # `*/` 用来匹配所有目录名，保存到 `dirs` 数组中。注意，此时数组中包含的是目录名后面带有 `/` 的字符串，如果需要去掉 `/`，可以使用 `${dirs[@]%/}` 命令。完整示例代码如下：
    dirs=( */ )
    dirs=("${dirs[@]%/}")
    echo "${dirs[@]}"
    # 输出结果为所有目录名，每个目录名占用一行。
}

# get_value_by_key <filename> <key> <key_index> <value_index>
# key_index,value_index 从0开始
function get_value_by_key() {
    filename=$1
    key=$2
    key_index=$3
    value_index=$4
    # grep 出符合条件的多行数据
    lines=$(grep "$key" $filename | grep -v '^#')
    # 遍历进行匹配
    for i in "${!lines[@]}"; do
        line=${lines[$i]}
        # 处理换行符
        line=$(echo $line | tr --delete '\n')
        line=$(echo $line | tr --delete '\r')
        # 根据空格或tab分割字符串
        arr=($line)
        if [ "${arr[$key_index]}" == "$key" ]; then
            echo ${arr[$value_index]}
            return $SUCCESS
        fi
    done
    return $FAILED
}

# get_value_by_index <filename> <value_index>
# value_index 从0开始
function get_value_by_index() {
    filename=$1
    value_index=$2
    OLD_IFS=$IFS
    IFS=$'\n'
    lines=(`grep -v '^#' $filename | awk -v N1="$(($value_index + 1))" '{print $N1}'`)
    IFS=$OLD_IFS
    echo "${lines[@]}"
}