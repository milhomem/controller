FROM centos:centos6

RUN yum -y update
RUN yum -y install httpd mod_ssl openssl mod_perl make automake gcc gcc-c++ kernel-devel tar unzip curl perl perl-devel perl-CPAN openssl-devel openssl-devel libxml2-devel mysql-devel bzip2 expat-devel perl-XML-LibXML perl-libxml-perl
RUN curl -L http://cpanmin.us | perl - App::cpanminus

ADD docker/httpd.conf /etc/httpd/conf.d/ssl.conf
ADD docker/docker_entrypoint.sh /docker_entrypoint.sh
RUN chmod +x /docker_entrypoint.sh

COPY src/ /var/www/html/
RUN chown apache:apache /var/www/html/logs
RUN chmod +x /var/www/html/sistema/rpc/admin.cgi /var/www/html/sistema/*.cgi

#RUN cd /var/www/html/ && cat cpanfile | perl -pe 's/.*'\''(.*)'\''.*/$1/' | while read module; do cpanm $module; done
RUN cpanm --notest --installdeps /var/www/html/

VOLUME [ "/var/log/httpd" ]
VOLUME [ "/etc/httpd/ssl" ]
VOLUME [ "/etc/httpd" ]

EXPOSE 443 80

CMD /docker_entrypoint.sh
