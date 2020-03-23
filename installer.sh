#!/bin/sh

#yaml파일 파싱하는 함수이다.
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|,$s\]$s\$|]|" \
        -e ":1;s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s,$s\(.*\)$s\]|\1\2: [\3]\n\1  - \4|;t1" \
        -e "s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s\]|\1\2:\n\1  - \3|;p" $1 | \
   sed -ne "s|,$s}$s\$|}|" \
        -e ":1;s|^\($s\)-$s{$s\(.*\)$s,$s\($w\)$s:$s\(.*\)$s}|\1- {\2}\n\1  \3: \4|;t1" \
        -e    "s|^\($s\)-$s{$s\(.*\)$s}|\1-\n\1  \2|;p" | \
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)-$s[\"']\(.*\)[\"']$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)-$s\(.*\)$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" | \
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]; idx[i]=0}}
      if(length($2)== 0){  vname[indent]= ++idx[indent] };
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) { vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, vname[indent], $3);
      }
   }'
}


#inventory.ini파일을 생성하는 함수이다.
function make_inventory {
   eval $(parse_yaml automation_config.yaml "config_")  #yaml파일을 파싱하여 인벤터리 파일을 생성함

   arr=("boot" "master" "mgmt" "proxy" "worker" "va" "end") #기본적인 노드들을 명시하는 부분 
   arr_count=0  #노드들을 하나하나 명시할 부분
   arr_node_name=() #노드의 이름을 저장하는 배열 ex)boot01, master01
   arr_node_ip=()  #노드의 ip를 저장하는 배열

   # vars define(va)  va 노드를 명시 해줬는지 확인 필요
   va_name=$(eval echo \$config_node_va_1 | cut -d" " -f2)

   #va노드가 없다면 작성x
   if [ "${#va_name}" -eq 0 ];then
      arr=()
      arr=("boot" "master" "mgmt" "proxy" "worker" "end") #기존 va 노드를 제거
   fi

   touch inventory.ini #host파일 생성 =>여기에 노드들을 하나하나 붙여 인벤터리 파일을 생성할 것임

   while [ 1 ] #while 문을 사용하여 boot->master->mgmt->proxy->worker->va순으로 각 노드 그룹을 명시하는 반복문이다
   do
   echo [${arr[${arr_count}]}] >> inventory.ini #노드의 그룹 이름을 입력한다 ex) [worker]
   count=1 #이 인자는 각 노드 그룹의 노드 수를 뜻한다. 처음엔 1로 명시하여 노드 수만큼 늘어나고 노드 그룹이 바뀌면(ex: boot->master) 다시 0으로 돌아간다.
      while [ 1 ]
      do
      arr_node_name+=($(eval echo \$config_node_${arr[${arr_count}]}_${count} | cut -d" " -f2)) #arr_node_name 배열에 각 노드의 이름을 파싱하여 넣는다
      arr_node_ip+=($(eval echo \$config_node_${arr[${arr_count}]}_${count}_ip | cut -d" " -f1)) #arr_node_ip 배열에 각 노드의 ip를 파싱하여 넣는다

      if [ ${#arr_node_name[${count}-1]} -eq 0 ];then #만약 인자가 더이상 존재하지 않는다면(노드 명의 길이가 null이면)
         arr_node_name=() # 노드이름과 ip를 담던 배열을 초기화 한다
         arr_node_ip=()
         break #ip와 name을 이어쓰던 작업을 마무리 하고 다음 노드로 넘어간다.
      else
         if [ ${arr_count} -eq 0 ];then  #boot노드라면
            echo "${arr_node_name[${count}-1]} ansible_host="127.0.0.1" ansible_connection=local" >> inventory.ini #인벤터리 형식에 맞게 bootnode입력
            count=`expr $count + 1` #인자를 더한다.
         else
            echo "${arr_node_name[${count}-1]} ansible_host=${arr_node_ip[${count}-1]}" >> inventory.ini #인벤터리 형식에 맞게 노드 name과 ip를 파일에 이어쓴다.
            count=`expr $count + 1` #인자를 더한다.
            continue
         fi
      fi
      done
   arr_count=`expr $arr_count + 1` #다음 노드 그룹으로 넘어간다.
   if [ ${arr[${arr_count}]} = "end" ];then #만약 arr(노드명을 명시한 배열) 에서 end라는 이름이 명시되면 모든 노드에 대한 이어쓰기가 마무리 됬으므로 반복문을 종료한다.
      break
   else
      continue
   fi
   done
}


#인벤토리 파일이 있는지 확인하며 생성하는 함수이다.
function check_inventory {
   if [ -f ./inventory.ini ];then 
      echo "기존 [ inventory.ini ] 파일을 삭제후 다시 시작해 주세요." 
   else
      make_inventory
   fi
}


#inventory파일을 확인, 생성한다.
check_inventory

# 환경변수를 등록하여 ansible의 오류없는 시작을 지원한다.
export ANSIBLE_HOST_KEY_CHECKING=False 

#ansible을 시작하여 환경 구성을 시작한다.
ansible-playbook -i inventory.ini playbook/install.yaml

#ver값을 파싱하기 위해 함수를 실행 한다.
eval $(parse_yaml automation_config.yaml "config_")

boot_pwd=$(eval echo ${config_node_boot_1_user_pwd} | cut -d" " -f1)

echo "${boot_pwd}" | sudo -S sudo chmod -R 777 /opt/ibm-cloud-private-3.2.0/
#icp설치를 시작한다.
echo "${boot_pwd}" | sudo -S docker run --net=host -t -e LICENSE=accept -v /opt/ibm-cloud-private-${config_util_icp_ver}/cluster:/installer/cluster ibmcom/icp-inception-amd64:${config_util_icp_ver}-ee install
