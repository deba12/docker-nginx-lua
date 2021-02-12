# Based on manual compile instructions at http://wiki.nginx.org/HttpLuaModule#Installation
FROM debian:stable

ENV VER_NGINX_DEVEL_KIT=0.3.1
ENV VER_LUA_NGINX_MODULE=0.10.19
ENV VER_NGINX=1.19.6
ENV VER_CONNECT_NGINX_MODULE=0.0.2
ENV VER_LUAJIT=2.1-20201229

ENV NGINX_DEVEL_KIT ngx_devel_kit-${VER_NGINX_DEVEL_KIT}
ENV LUA_NGINX_MODULE lua-nginx-module-${VER_LUA_NGINX_MODULE}
ENV NGINX_ROOT=/nginx
ENV WEB_DIR ${NGINX_ROOT}/html
ENV CONNECT_NGINX_MODULE ngx_http_proxy_connect_module-${VER_CONNECT_NGINX_MODULE}
ENV LUAJIT=luajit2-v${VER_LUAJIT}

ENV LUAJIT_LIB /usr/local/lib
ENV LUAJIT_INC /usr/local/include/luajit-2.1

RUN DEBIAN_FRONTEND=noninteractive apt-get -qq update && \
	apt-get -qq -y install wget make libpcre3 libpcre3-dev zlib1g-dev libssl-dev gcc patch

# Download
RUN wget http://nginx.org/download/nginx-${VER_NGINX}.tar.gz
RUN wget https://github.com/openresty/luajit2/archive/v${VER_LUAJIT}.tar.gz -O ${LUAJIT}.tar.gz
RUN wget https://github.com/simpl/ngx_devel_kit/archive/v${VER_NGINX_DEVEL_KIT}.tar.gz -O ${NGINX_DEVEL_KIT}.tar.gz
RUN wget https://github.com/openresty/lua-nginx-module/archive/v${VER_LUA_NGINX_MODULE}.tar.gz -O ${LUA_NGINX_MODULE}.tar.gz
RUN wget https://github.com/chobits/ngx_http_proxy_connect_module/archive/v${VER_CONNECT_NGINX_MODULE}.tar.gz -O ${CONNECT_NGINX_MODULE}.tar.gz
# Untar
RUN tar -xzvf nginx-${VER_NGINX}.tar.gz && rm nginx-${VER_NGINX}.tar.gz
RUN tar -xzvf ${NGINX_DEVEL_KIT}.tar.gz && rm ${NGINX_DEVEL_KIT}.tar.gz
RUN tar -xzvf ${LUA_NGINX_MODULE}.tar.gz && rm ${LUA_NGINX_MODULE}.tar.gz
RUN tar -xzvf ${CONNECT_NGINX_MODULE}.tar.gz && rm ${CONNECT_NGINX_MODULE}.tar.gz
RUN tar -zxvf ${LUAJIT}.tar.gz && rm ${LUAJIT}.tar.gz

# Nginx with LuaJIT
WORKDIR luajit2-${VER_LUAJIT}
RUN make -j 4
RUN make install

WORKDIR /nginx-${VER_NGINX}
RUN patch -p1 < /${CONNECT_NGINX_MODULE}/patch/proxy_connect_rewrite_1018.patch
RUN ./configure --prefix=${NGINX_ROOT} --with-ld-opt="-Wl,-rpath,${LUAJIT_LIB}" \
	--add-module=/${NGINX_DEVEL_KIT} --add-module=/${LUA_NGINX_MODULE} --add-module=/${CONNECT_NGINX_MODULE} \
	--with-http_ssl_module --with-pcre
RUN make -j4
RUN make install
RUN ln -s ${NGINX_ROOT}/sbin/nginx /usr/local/sbin/nginx

# ***** MISC *****
WORKDIR ${WEB_DIR}
EXPOSE 80
EXPOSE 443

# ***** CLEANUP *****
RUN rm -rf /nginx-${VER_NGINX}
RUN rm -rf /${NGINX_DEVEL_KIT}
RUN rm -rf /${LUA_NGINX_MODULE}
# TODO: Uninstall build only dependencies?
# TODO: Remove env vars used only for build?

# This is the default CMD used by nginx:1.9.2 image
CMD ["nginx", "-g", "daemon off;"]
