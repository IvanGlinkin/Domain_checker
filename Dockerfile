FROM alpine:latest

RUN apk update && apk add --no-cache bash nmap bind-tools geoip curl
COPY . . 
RUN chmod 755 ./domain_checker.sh
ENTRYPOINT ["./domain_checker.sh"]
