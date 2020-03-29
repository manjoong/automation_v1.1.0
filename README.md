# automation_v1.1.0

설치 환경 
os : centos 7.x, redhat os
노드수 : boot node 필요, 마스터 노드 필요, 워커노드 필요
접속 계정 권한: root권한 필수 필요

설치 단계
1. boot노드에서 각 노드에 ssh 접속 가능하게 설정(password 없이)
2. yum install ansible -y 
3. chmod +x installer.sh
4. ./installer.sh
5. 클러스터 설치 명령어 실행
6. 클러스터 구축 완료 확인
kubectl get node


