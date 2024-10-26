

FROM 基于那个镜像
CMD 容器默认的启动命令.
RUN 执行命令.
COPY 复制文件或者目录到容器中
ADD 和COPY相同.但是如果是压缩文件,她会解压.
ENTRYPOINT 和CMD相同.但是他不会覆盖docker run时指定的命令
ENV <key> <value> 设置变量
WORKDIR 指定工作目录
