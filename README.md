# automation_v1.1.0

## 설치 환경 
### os : 
centos 7.x, redhat os
### 필요파일: 
1. congig.yaml
2. icp 설치 tar파일
3. docker-install.bin파일
### 접속 계정 권한: 
root권한 필수 필요
### 네트워크:
yum 통신 사용하므로 외부 아웃바운드 트래픽 사용가능 확인 

## 설치 단계
1. boot노드에서 각 노드에 ssh 접속 가능하게 설정(password 없이)
2. 각 노드별 필요 디스크 마운트 실행
3. yum install ansible git -y 
4. git clone https://github.com/manjoong/automation_v1.1.0.git  && cd automation_v1.1.0 (boot노드에서 실행)
5. automation_config.yaml 작성
6. chmod +x installer.sh
7. ./installer.sh
8. 클러스터 설치 명령어 실행
(docker run --net=host -t -e LICENSE=accept -v /opt/ibm-cloud-private-${icp_ver}/cluster:/installer/cluster ibmcom/icp-inception-amd64:${_icp_ver}-ee install)
9. 클러스터 구축 완료 확인

