logparser
=========
Yet another (DHCP) router log parser

My router sends me its syslog file every hour in e-mail. This little script is intended to process these e-mails; since the router cannot send only the new logfile records, instead it sends the whole file every time, I need to take the diff from every last 2 messages and only store the new information.
Syslog also contains (for me) useless information, those need to be left out and also, the e-mail headers are also unnecessary. This script makes all this 'magic' possible.

You can find sample outputs in the _sample/ folder.

After the diffs are stored, they can be processed - put it in a key-value store, work with them, calculate, produce statistics, fancy diagrams, everything else.


TODO:
-----
- [x] ResultStore: sort by last modification date, ascending -> generate all of the diffs file by file
- [x] support for finding the last processed file & work with all the rest
- [ ] support for debug mode
- [ ] writing to exec logfile
- [ ] logrotate function

- [ ] investigate: 'ls -t' vs. current implemented find + epoch time sort

Main TODO:
- [ ] use a key-value store for the data
- [ ] create fancy output & statistics from the MAC address data
