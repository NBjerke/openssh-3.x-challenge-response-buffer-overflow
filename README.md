# openssh-3.x-challenge-response-buffer-overflow
SSH binary for exploiting OpenSSH 3.x - Challenge-Response Buffer Overflow

More info:

https://www.exploit-db.com/exploits/21578


## Build

You can build it this way:

```
docker build -t openssh3x https://github.com/irsl/openssh-3.x-challenge-response-buffer-overflow.git
```

## Usage

The entry point is the ssh cli, so you can use it this way:

```
docker run --rm -it openssh3x ...ssh parameters...
```
