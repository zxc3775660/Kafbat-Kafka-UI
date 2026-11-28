FROM scratch

# 1. 掛載極簡 Alpine 根系統（提供 sh 與 tar，僅 3.6MB）
ADD alpine-minirootfs.tar.gz /

# 2. 放入切割後的 JRE 25 + 離線 APK + api.jar 分卷（每檔皆 <= 80MB）
COPY payload.tar.gz.part_* /tmp/parts/

# 3. 合併解壓縮、離線安裝修補套件並建立非 root 帳號
RUN cat /tmp/parts/payload.tar.gz.part_* | tar -xzf - -C / && \
    rm -rf /tmp/parts && \
    apk add --no-cache --allow-untrusted /tmp/apk-cache/*.apk && \
    rm -rf /tmp/apk-cache && \
    addgroup -S kafkaui && adduser -S kafkaui -G kafkaui && \
    chown kafkaui:kafkaui /api.jar && \
    mkdir /etc/kafkaui/ && chown kafkaui /etc/kafkaui

USER kafkaui
WORKDIR /

ENV JAVA_HOME="/opt/java/openjdk" \
    PATH="/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    JAVA_OPTS=""

EXPOSE 8080

CMD ["sh", "-c", "java --add-opens java.rmi/javax.rmi.ssl=ALL-UNNAMED $JAVA_OPTS -jar api.jar"]
