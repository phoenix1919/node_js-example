FROM ubuntu:disco

RUN apt-get update
RUN apt-get install -y python nodejs
RUN mkdir /var/www
ADD lib/serious-calculations.js /var/www/app.js

CMD ["/usr/bin/node", "/var/www/app.js"] 
