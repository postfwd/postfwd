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
docker run -it postfwd:testing
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


## 3 Configure the container

For reasonable operation you should configure postfwd. First you should create your own ruleset. Please look at the manpage or [postfwd.org](https://postfwd.org) for more information on this topic. Save your ruleset to a file on the docker host - it will be further refered as:

```bash
/path/to/ruleset
```

```bash
Now specify the program options via the container environment. The following settings are available:

    # use 'postfwd1' or 'postfwd2' to switch between versions
    # go to http://postfwd.org/versions.html for more info
    - PROG=postfwd1
    # port for postfwd
    - PORT=10040
    # configuration file
    - CONF=postfwd.cf
    # request cache in seconds. use '0' to disable
    - CACHE=60
    # additional arguments, see postfwd -h or man page for more
    - EXTRA=--no_parent_dns_cache --noidlestats --summary=600
```

### 3.1 docker

    Run postfwd2 instead of postfwd1:

```bash
    docker run -v /path/to/ruleset:/etc/postfwd/postfwd.cf:ro -e PROG=postfwd2 -it postfwd:testing
```

    Disable request-cache, enable verbose logging:

```bash
    docker run -v /path/to/ruleset:/etc/postfwd/postfwd.cf:ro -e CACHE=0 -e EXTRA="-v" -it postfwd:testing
```

b.) docker-compose

    Run postfwd2 instead of postfwd1, disable cache, enable verbose logging (docker-compose.yml):

```bash
    #
    # docker-compose.yml
    #

    version: '2' 

    services:

      postfwd:
        image: postfwd/postfwd:testing
        environment:
          - PROG=postfwd2
          - CACHE=0
          - EXTRA=-vv --no_parent_dns_cache --noidlestats --summary=600
        restart: always
        ports:
          - 127.0.0.1:10040:10040
        volumes:
          - /path/to/ruleset:/etc/postfwd/postfwd.cf:ro
```

