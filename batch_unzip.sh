#!/bin/bash

# 遍历目录下的所有.zip文件
for file in *.zip
do
  # 如果是文件
  if [ -f "$file" ]; then
    echo "正在解压缩文件： $file"
    # 解压缩文件
    unzip -o "$file"
    # 如果解压缩成功，删除源.zip文件
    if [ $? -eq 0 ]; then
      echo "解压缩完成，正在删除文件： $file"
      rm "$file"
    fi
  fi
done