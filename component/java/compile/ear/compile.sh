#!/bin/bash
function STOUT(){
    $@ 1>/tmp/standard_out 2>/tmp/error_out
    if [ "$?" -eq "0" ]
    then
        cat /tmp/standard_out | awk '{print "[COUT]", $0}'
        cat /tmp/error_out | awk '{print "[COUT]", $0}' >&2
        return 0
    else
        cat /tmp/standard_out | awk '{print "[COUT]", $0}'
        cat /tmp/error_out | awk '{print "[COUT]", $0}' >&2
        return 1
    fi
}

function STOUT2(){
    $@ 1>/dev/null 2>/tmp/error_out
    if [ "$?" -eq "0" ]
    then
        cat /tmp/error_out | awk '{print "[COUT]", $0}' >&2
        return 0
    else
        cat /tmp/error_out | awk '{print "[COUT]", $0}' >&2
        return 1
    fi
}

declare -A map=(
    ["git-url"]="" 
    ["target"]=""
)
data=$(echo $CO_DATA |awk '{print}')
for i in ${data[@]}
do
    temp=$(echo $i |awk -F '=' '{print $1}')
    value=$(echo $i |awk -F '=' '{print $2}')
    for key in ${!map[@]}
    do
        if [ "$temp" = "$key" ]
        then
            map[$key]=$value
        fi
    done
done

if [ "" = "${map["git-url"]}" ]
then
    printf "[COUT] Handle input error: %s\n" "git-url"
    printf "[COUT] CO_RESULT = %s\n" "false"
    exit
fi

if [ "" = "${map["target"]}" ]
then
    printf "[COUT] no target input\n" "target"
    printf "[COUT] CO_RESULT = %s\n" "false"
    exit
fi

STOUT git clone ${map["git-url"]}
if [ "$?" -ne "0" ]
then
    printf "[COUT] CO_RESULT = %s\n" "false"
    exit
fi
pdir=`echo ${map["git-url"]} | awk -F '/' '{print $NF}' | awk -F '.' '{print $1}'`
cd ./$pdir
if [ ! -f "build.gradle" ]
then
    printf "[COUT] file build.gradle not found! \n"
    printf "[COUT] CO_RESULT = %s\n" "false"
    exit
fi

STOUT2 gradle ear
if [ "$?" -ne "0" ]
then
    printf "[COUT] gradle ear fail\n"
    printf "[COUT] CO_RESULT = %s\n" "false"
    exit
fi

earpath=$(find `pwd` -name "*.ear")
if [ "$earpath" = "" ]
then
    printf "[COUT] can not find a ear file after project build%s\n"
    printf "[COUT] CO_RESULT = %s\n" "false"
    exit
fi
echo $earpath

STOUT curl -i -X PUT -T $earpath ${map["target"]} 2>/dev/null

if [ "$?" -eq "0" ]
then
    printf "[COUT] download ear url : %s\n" ${map["target"]}
    printf "[COUT] CO_RESULT = %s\n" "true"
else
    printf "[COUT] upload %s to %s fail %s\n" $earpath ${map["target"]}
    printf "[COUT] CO_RESULT = %s\n" "false"
fi
exit