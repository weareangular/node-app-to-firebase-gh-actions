FROM node:15.8.0-alpine3.10

# Update distro
RUN apk update && apk upgrade && apk add bash rsync jq

# Set the timezone in docker
RUN apk --update add tzdata && cp /usr/share/zoneinfo/America/Bogota /etc/localtime && echo "America/Bogota" > /etc/timezone && apk del tzdata

# Install firebase-cli
RUN npm install -g firebase-tools 

# Switch Work Directory
WORKDIR /opt/firebase-warp

# Copy files
COPY . .

# Start
ENTRYPOINT ["/bin/bash", "/opt/firebase-warp/entrypoint.sh"]
CMD ["--h"]
