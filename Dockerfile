FROM centos:7

# install dependencies
RUN yum install -y httpd php
RUN ln -sf /dev/stdout /var/log/httpd/access_log
RUN ln -sf /dev/stderr /var/log/httpd/error_log
COPY index.php /var/www/html/
COPY fonetwish.php /var/www/html/

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
