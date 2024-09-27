# Use the official PHP 8 image with Apache
FROM php:8-apache

# Copy the source code into the container
COPY src/ /var/www/html/

# Configure Apache to avoid "ServerName" issues
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Expose port 7001
EXPOSE 7001

# Update package lists and install system dependencies for Imagick
RUN apt-get update && apt-get install -y \
    git \
    libmagickwand-dev \
    libmagickcore-dev \
    pkg-config \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    zlib1g-dev \
    libtool \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip pdo pdo_mysql

# Install PHP extensions using the installer script
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install necessary PHP extensions (except Imagick)
RUN install-php-extensions \
    xdebug \
    xml \
    iconv \
    simplexml \
    xmlreader

# Manually install Imagick from GitHub
RUN git clone https://github.com/Imagick/imagick.git /usr/src/imagick \
    && cd /usr/src/imagick \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable imagick

# Enable Apache's mod_rewrite
RUN a2enmod rewrite

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the correct permissions for the web root
RUN chown -R www-data:www-data /var/www/html

# Ensure the Apache .htaccess works as expected by allowing overrides
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
