FROM ubuntu:latest

RUN apt-get update && apt-get install -y nmap host geoip-bin curl
COPY . . 
RUN chmod 755 ./domain_checker.sh
ENTRYPOINT ["./domain_checker.sh"]