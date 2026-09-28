FROM nginx:stable-alpine

LABEL org.opencontainers.image.source="https://github.com/inerasable0203/CICD_practice"

COPY index.html /usr/share/nginx/html/index.html
