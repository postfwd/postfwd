# postfwd docker support

To run postfwd in a docker container you will need at least version 1.36-devel2. The following examples fetch postfwd from the ["testing"-branch at GitHub](https://github.com/postfwd/postfwd/tree/testing). Furthermore you can find these versions at the [postfwd development page](https://postfwd.org/DEVEL/?C=M;O=D). This will change after the final release of version 1.36+.

### Get the postfwd docker files:

via GitHub:
```bash
git clone https://github.com/postfwd/postfwd --branch testing --single-branch postfwd
```

via postfwd.org:
```bash
wget https://postfwd.org/DEVEL/postfwd-latest.tar.gz && gzip -dc postfwd-latest.tar.gz | tar -xf - && rm postfwd-latest.tar.gz
```

### Configure your postfwd ruleset:

Change to the postfwd docker sample sub-directory:
```bash
cd postfwd/docker
```

Edit the ruleset postfwd.cf

For reasonable operation the default ruleset should be edited. Refer to the [postfwd manual](https://postfwd.org/doc.html) for more information.


### Build and run the container:

Edit the Dockerfile and run:
```bash
docker build -t postfwd:testing .
docker run -v `pwd`/postfwd.cf:/etc/postfwd/postfwd.cf:ro -it postfwd:testing
```

Edit the docker-compose.yml file and run:
```bash
docker-compose build --pull
docker-compose up
```

