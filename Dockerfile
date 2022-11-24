FROM p6steve/rakudo:basic

RUN apt-get update && cd ~
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
RUN apt-get install awscli -y

#CMD aws configure
