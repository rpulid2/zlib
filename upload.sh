#!/bin/bash

LGTM_SERVER='https://lgtm-poc.devtools.intel.com'
AUTH_BAERER='9c382de26e882a7591d7d0c0ff510ad3874e3ccc904f79e14c8f20c19f5017d4'
FILE='zlib_database.zip'
QUERYSET='/home/rpulido/Documents/IPAS/CodeQL/codeqlgit/cpp/ql/src/'

# Adding CodeQL to PATH

export PATH=$PATH:/home/rpulido/Documents/IPAS/CodeQL/codeql-linux64/

## Resolving Languages

codeql resolve languages

## Resolving QlPacks

codeql resolve qlpacks

## Preparing code
if [ -d "build" ]; then
	rm -r build
fi


mkdir build

cd build

cmake ../

## Build with codeql
if test -d "zlib_database"; then
	rm -r zlib_database
fi

codeql database create zlib_database --language=cpp --command=make

## Preparing Database

if test -f $FILE; then
	rm $FILE
fi

if test -f zlib_database/ddfile.iso; then
	echo "File already exists"
else
	echo "Creating file to increase database size"
	cp /home/rpulido/Documents/Non-IPAS/Intel/MyLearning/LinuxFoundation/Resources/kali-linux-light-2016.1-amd64.iso zlib_database/ddfile.iso
	dd if=/dev/zero of=test.img bs=1024 count=0 seek=20480000
	ls
	cp ../zlib_test01.zip zlib_database
fi

if test -f zlib_database/ddfile.iso; then
	echo "File dd is in place"
else
	echo "Can't find file, exiting."
	exit 0
fi
## Analyzing
codeql resolve queries $QUERYSET
codeql database analyze zlib_database $QUERYSET --format=csv --output=zlib_database.csv zlib_database

codeql database interpret-results --format=sarif-latest --output=zlib_database/results.sarif zlib_database

codeql database bundle zlib_database --output=$FILE --include-results

echo "Checking database file"
du -sh $FILE


SESSION_ID=$(curl -s --insecure -X POST $LGTM_SERVER/api/v1.0/snapshots/1000018/cpp?commit=12345 -H 'Accept: application/json' -H "Authorization: Bearer $AUTH_BAERER" | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/\042'id'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p)
echo "Get Session ID"
echo "Sesison ID $SESSION_ID"
sleep 5

echo "Running curl --insecure -X PUT $LGTM_SERVER/api/v1.0/snapshots/uploads/$SESSION_ID --data-binary @$FILE -H 'Content-Type: application/zip' -H 'Authorization: Bearer $AUTH_BAERER'"
curl --insecure -X PUT $LGTM_SERVER/api/v1.0/snapshots/uploads/$SESSION_ID --data-binary @$FILE -H 'Content-Type: application/zip' -H "Authorization: Bearer $AUTH_BAERER"

for i in `seq 8`;
do 
	echo "Waiting $i secs"
	sleep 1
done
echo "Running curl --insecure -X POST $LGTM_SERVER/api/v1.0/snapshots/uploads/$SESSION_ID -H 'Accept: application/json' -H 'Authorization: Bearer $AUTH_BAERER'"

curl --insecure -X POST $LGTM_SERVER/api/v1.0/snapshots/uploads/$SESSION_ID -H 'Accept: application/json' -H "Authorization: Bearer $AUTH_BAERER"


