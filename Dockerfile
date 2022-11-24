FROM p6steve/rakudo:basic

#viz. https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions
RUN apt-get update && cd ~
RUN apt-get -y install unzip
#RUN curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'  -o "awscliv2.zip" && \
RUN curl 'https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip' -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install

CMD aws configure
