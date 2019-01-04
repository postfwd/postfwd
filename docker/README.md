# postfwd docker support

Important: Please look at [postfwd.org/docker](https://postfwd.org/docker) for the latest version of this information!

To run postfwd in a docker container you will need use at least version 1.36 of postfwd. You can use one of the pre-built images `postfwd/postfwd:stable` or `postfwd/postfwd:devel` from [DockerHub](https://hub.docker.com/r/postfwd/postfwd) or download the [postfwd distibution](https://postfwd.org) and build the image by yourself.

## 1 Using a pre-built image

### 1.1 docker

1.1.1 Get the image:
```bash
docker pull postfwd/postfwd:stable
```

1.1.2 Execute a container based on that image:
```bash
docker run -it postfwd/postfwd:stable
```

### 1.2 docker-compose

1.2.1 Create `docker-compose.yml`:
```
version: '2'

services:
  postfwd:
    image: postfwd/postfwd:stable
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

The files `Dockerfile` and `docker-compose.yml` which were used to build the images at DockerHub can be found within
the subfolder `docker/` of the postfwd distribution. You can find it at:

2.1.1 [GitHub](https://github.com/postfwd/postfwd):
```bash
git clone https://github.com/postfwd/postfwd --branch master --single-branch postfwd
```

2.1.2 [postfwd.org](https://postfwd.org):
```bash
wget https://postfwd.org/postfwd-latest.tar.gz && gzip -dc postfwd-latest.tar.gz | tar -xf - && rm postfwd-latest.tar.gz
```

### 2.2 docker

2.2.1 Edit the `Dockerfile` and build the image:
```bash
docker build --no-cache --pull -t postfwd:stable .
```
2.2.2 Execute a container based on that image:
```bash
docker run -it postfwd:stable
```

### 2.3 docker-compose

2.3.1 Edit the `Dockerfile` and the `docker-compose.yml` file and build the image:
```bash
docker-compose build --no-cache --pull
```

2.3.2 Execute the container:
```bash
docker-compose up
```


## 3 Configure the container

For reasonable operation you should configure postfwd. First create your own ruleset. Please look at the manpage or [postfwd.org](https://postfwd.org) for more information on this topic. Save your ruleset to a file on the docker host - it will be further refered as:

```
/path/to/ruleset
```

Now specify the program options via the container environment. The following settings are available with these default values:

```
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
- EXTRA=--noidlestats --summary=600
```

### 3.1 docker

Run postfwd2 instead of postfwd1:

```bash
docker run -v /path/to/ruleset:/etc/postfwd/postfwd.cf:ro -e PROG=postfwd2 -it postfwd:stable
```

Disable request-cache, enable verbose logging:

```bash
docker run -v /path/to/ruleset:/etc/postfwd/postfwd.cf:ro -e CACHE=0 -e EXTRA="-v" -it postfwd:stable
```

#### 3.2 docker-compose

Run postfwd2 instead of postfwd1, disable cache, enable verbose logging via `docker-compose.yml`:

```
#
# docker-compose.yml
#

version: '2' 

  services:

    postfwd:
      image: postfwd/postfwd:stable
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

