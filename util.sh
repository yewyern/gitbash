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

# get_value_by_key <filename> <key> <key_index> <value_index>
function get_value_by_key() {
    filename=$1
    key=$2
    key_index=$3
    value_index=$4
    # grep 出符合条件的多行数据
    lines=`grep "$key" $filename`
    # 遍历进行匹配
    for i in "${!lines[@]}";
    do
        line=${lines[$i]}
        # 处理换行符
        line=`echo $line | tr --delete '\n'`
        line=`echo $line | tr --delete '\r'`
        # 根据空格或tab分割字符串
        arr=($line)
        if [ "${arr[$key_index]}" == "$key" ]; then
            echo ${arr[$value_index]}
            return $SUCCESS
        fi
    done
    return $FAILED
}
