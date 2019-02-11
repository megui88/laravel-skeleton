FROM nginx:latest

ENV TZ=America/Argentina/Buenos_Aires
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && set -x \
	&& apt update \
	&& apt install --no-install-recommends --no-install-suggests -y apt-transport-https lsb-release ca-certificates openssl wget \
	&& wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
	&& sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' \
	&& apt update \
	&& apt install --no-install-recommends --no-install-suggests -y supervisor git-core php7.2 php7.2-common php7.2-cli php7.2-fpm php7.2-gd php7.2-mysql php7.2-xml php7.2-curl php7.2-mbstring php7.2-zip composer mysql-client\
	&& apt remove --purge --auto-remove -y apt-transport-https  lsb-release wget \
	&& rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/php.list \
    && usermod -u 1000 www-data \
    && rm -Rf /etc/nginx/nginx.conf \
    && mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled /run/php \
    && touch /etc/nginx/sites-available/default.conf \
    && ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

ADD ./Docker/supervisord.conf /etc/supervisord.conf
ADD ./Docker/nginx.conf /etc/nginx/nginx.conf
ADD ./Docker/www.conf /etc/php/7.2/fpm/pool.d/www.conf
ADD ./Docker/php.ini /etc/php/7.2/fpm/php.ini
ADD ./Docker/default.conf /etc/nginx/sites-available/default.conf

WORKDIR /usr/share/nginx/html
ADD ./ /usr/share/nginx/html/
RUN chown www-data:www-data -Rf /usr/share/nginx/html

ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install -o -a --prefer-dist

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
