# postfwd docker support

To run postfwd in a docker container you will need to access the development aka testing branch (at least version 1.36-devel2). You can use the pre-built image "postfwd/postfwd:testing" from DockerHub or download the postfwd distibution and build the image by yourself.


## 1 Using a pre-built image

### 1.1 docker

1.1.1 Get the image:
```bash
docker pull postfwd/postfwd:testing
```

1.1.2 Execute a container based on that image:
```bash
docker run -it postfwd/postfwd:testing
```

### 1.2 docker-compose

1.2.1 Create docker-compose.yml:
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

1.2.2 Execute the container:
```bash
docker-compose up
```


## 2 Building your own image

### 2.1 Get the postfwd docker files

The files "Dockerfile" and "docker-compose.yml" which were used to build the images at DockerHub can be found within the
"docker"-subfolder of the postfwd distribution. You can find it at:

2.1.1 [GitHub](https://github.com/postfwd/postfwd/tree/testing):
```bash
git clone https://github.com/postfwd/postfwd --branch testing --single-branch postfwd
```

2.1.2 [postfwd.org/DEVEL](https://postfwd.org/DEVEL/?C=M;O=D):
```bash
wget https://postfwd.org/DEVEL/postfwd-latest.tar.gz && gzip -dc postfwd-latest.tar.gz | tar -xf - && rm postfwd-latest.tar.gz
```

### 2.2 docker

2.2.1 Edit the Dockerfile and build the image:
```bash
docker build --no-cache --pull -t postfwd:testing .
```
2.2.2 Execute a container based on that image:
```bash
docker run -v `pwd`/postfwd.cf:/etc/postfwd/postfwd.cf:ro -it postfwd:testing
```

### 2.3 docker-compose

2.3.1 Edit the Dockerfile and the docker-compose.yml file and build the image:
```bash
docker-compose build --no-cache --pull
```

2.3.2 Execute the container:
```bash
docker-compose up
```

