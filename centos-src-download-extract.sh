#!/bin/bash
#version diffs

cd /home
if [ ! -d "download-centos" ];then 
	mkdir -p download-centos/centos
	mkdir -p download-centos/centos-extract
	echo "availableness_test" > download-centos/centos/availableness_test
fi

if [ "$1" = "7" ];then
        sub_version=(7.0.1406 7.1.1503 7.2.1511 7.3.1611 7.4.1708 7.5.1804 7.6.1810 7.7.1908 7.8.2003 7.9.2009)
        kernel_version="kernel-3.10.0"
        url_diff="os"
elif [ "$1" = "8" ];then
        sub_version=(8.0.1905 8.1.1911 8.2.2004 8.3.2011 8.4.2105 8-stream)
        kernel_version="kernel-4.18.0"
        url_diff="BaseOS"
fi
#download page

cd /home/download-centos/centos
if [ ! -n "$1" ];then
	echo "======================================================Error============================================================="
        echo "No version number, please run this script as: ./centos-addr-pull.sh R U"
	exit 1
else
	echo "===============================================Get download page========================================================"
	url_prefix="https://vault.centos.org/${sub_version[$2]}/${url_diff}/Source/SPackages/"
	echo "${url_prefix}"
	echo "===============================================Download the webpage====================================================="
	
	if [ -f "$1.$2.html" ];then
		echo "$1.$2.html exist, skip"
	else
		wget ${url_prefix} -O $1.$2.html
	fi
fi
packet=$(egrep -o "(${kernel_version})(.*)(.src.rpm\")" $1.$2.html | sed 's/.$//')
packet_num=$(echo ${packet} | grep -o "kernel" | wc -l)
packet_num_count=${packet_num}

for ((i=1;i<=${packet_num};i++))
do
        packet_addr=$(echo ${url_prefix}$(echo ${packet} | cut -d ' ' -f ${i}))
	echo "===============================================Get the download link===================================================="
	if [ ${packet_num_count} ];then
                ((packet_num_count--))
        fi
	echo "${packet_num_count} packages remains to download."
	
	cd /home/download-centos/centos
        echo "${packet_addr}"
	echo "==============================================Begin to download package================================================="
	if [ -f "$(echo ${packet} | cut -d ' ' -f ${i})" ];then
		echo "Exists, skip"
		continue
	else
		wget ${packet_addr}
	fi
	packet_serial=$(echo ${packet} | cut -d ' ' -f ${i} | sed 's/.src.rpm//g'| sed 's/kernel/linux/g')
	echo "Done"
	echo "============================================Begin to extract tar package================================================"
	rpm2cpio $(echo ${packet} | cut -d ' ' -f ${i}) | cpio -vi
	mv $(find ./ -name '*.tar.xz') /home/download-centos/centos-extract/${packet_serial}.tar.xz
	echo "Done"
	echo "===================================================Begin to unzip======================================================="
	cd /home/download-centos/centos-extract/
	echo "Unzip ${packet_serial}.tar.xz"
	tar -Jxf ${packet_serial}.tar.xz
	echo "Done"
	echo "============================================Begin to clean redundant file==============================================="
	cd /home/download-centos/centos
	if [ -f "availableness_test" ];then
        	echo "Start cleanning"
        	rm -f *.config c* e* f* g* kabi* kvm* linux* M* m* p* r* s* x* *patch kernel*bz2 *spec
        	echo "Done"
	else
        	echo "Wrong, please check"
	fi
done

