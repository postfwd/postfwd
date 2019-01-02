# postfwd docker support

To run postfwd in a docker container you will need to access the development aka testing branch (at least version 1.36-devel2). You can use the pre-built image "postfwd/postfwd:testing" from DockerHub or download the postfwd distibution and build the image by yourself.


## Using a pre-built image

### docker

Get the image:
```bash
docker pull postfwd/postfwd:testing
```

Execute a container based on that image:
```bash
docker run -it postfwd/postfwd:testing
```

### docker-compose

Create docker-compose.yml:
```bash
version: '2'

services:
  postfwd-testing:
    image: postfwd/postfwd:testing
    restart: always
    ports:
      # Modify the port below if required!
      - 127.0.0.1:10040:10040
    volumes:
      # Do not forget to create your ruleset an change /path/to/ruleset below!
      - /path/to/ruleset/postfwd.cf:/etc/postfwd/postfwd.cf:ro
```

Execute the container:
```bash
docker-compose up
```


## Building your own image

### Get the postfwd docker files:

via [GitHub](https://github.com/postfwd/postfwd/tree/testing):
```bash
git clone https://github.com/postfwd/postfwd --branch testing --single-branch postfwd
```

via [postfwd.org/DEVEL](https://postfwd.org/DEVEL/?C=M;O=D):
```bash
wget https://postfwd.org/DEVEL/postfwd-latest.tar.gz && gzip -dc postfwd-latest.tar.gz | tar -xf - && rm postfwd-latest.tar.gz
```

### docker

Edit the Dockerfile build the image:
```bash
docker build --no-cache --pull -t postfwd:testing .
```
Execute a container based on that image:
```bash
docker run -v `pwd`/postfwd.cf:/etc/postfwd/postfwd.cf:ro -it postfwd:testing
```

### docker-compose

Edit the Dockerfile and the docker-compose.yml file build the image:
```bash
docker-compose build --no-cache --pull
```

Execute the container:
```bash
docker-compose up
```
