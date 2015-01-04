# BDSH

## TIPS

```bash
sed -n Xp __FILE__ #X is line
grep -a -P "\x00\x09" resTest
grep -k
cut -d '' -f1 # cut on null character
sed -i //d ^$key$sep
sed -i /^$key$sep$value$/
sed -i "s/$key$sep.*/$key$sep/"
sed "s/trucachanger/nouveautruc/"
sed "/trucavirer/d"
#tu rajoute un -i pour modifier le fichier
#be careful : for cut on a lot of characters
for line in $(grep -aP "key.+" sh.db) ; do echo $line ; done
for line in $(grep -aP "key.+" sh.db | cut -d '' -f1) ; do echo $line ; done
IFS=$(echo)
```

more tips in tricks.sh

http://michel.mauny.net/sii/variables-shell.html
