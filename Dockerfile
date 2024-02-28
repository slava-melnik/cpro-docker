FROM ubuntu:22.04 as php-base
ADD config /tmp/config
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y php8.3 php8.3-fpm php8.3-mbstring php8.3-xml php8.3-gd php8.3-curl nginx

FROM php-base
ADD dist /tmp/dist
ADD local /var/www/local
RUN apt install libboost-dev php-dev libxml2-dev -y
RUN cd /tmp/dist && \
    tar -xf linux-amd64_deb.tgz && \
    linux-amd64_deb/install.sh && \
    apt install ./linux-amd64_deb/lsb-cprocsp-devel*.deb && \
    apt install ./lsb-cprocsp-devel*.deb && \
    tar xvf cades-linux-amd64.tar.gz && \
    apt install \
    ./cades-linux-amd64/cprocsp-pki-cades*.deb \
    ./cades-linux-amd64/cprocsp-pki-phpcades*.deb
    # меняем Makefile.unix
RUN PHP_BUILD=`php -i | grep 'PHP Extension => ' | awk '{print $4}'` && \
    EXT_DIR=`php -i | grep 'extension_dir => ' | awk '{print $3}'` && \
    sed -i "s#PHPDIR=/php#PHPDIR=/usr/include/php/$PHP_BUILD#g" /opt/cprocsp/src/phpcades/Makefile.unix && \
    cd /opt/cprocsp/src/phpcades && \
    # применяем патч
    apt install zip unzip -y && \
    unzip /tmp/dist/php8_support.patch.zip && \
    patch -p0 < php8_support.patch && \
    # собираем
    eval `/opt/cprocsp/src/doxygen/CSP/../setenv.sh --64`; make -f Makefile.unix && \

    mv libphpcades.so "$EXT_DIR" && \
    echo "extension=libphpcades.so" > /etc/php/8.3/cli/conf.d/20-libphpcades.ini

EXPOSE 9000
CMD ["php-fpm"]
