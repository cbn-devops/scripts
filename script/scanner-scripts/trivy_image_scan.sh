#!/bin/bash -e

image_name=$IMAGE_NAME
build_docker=$BUILD_DOCKER

if [ $build_docker == true ];then
	sudo yum install make wget -y
	git clone https://github.com/aquasecurity/trivy-db.git
	cd trivy-db
	wget -q https://raw.githubusercontent.com/linux-on-ibm-z/scripts/refs/heads/master/script/trivy.patch
	git apply trivy.patch
 
  	GO_VERSION=1.23.1
   	wget -q https://storage.googleapis.com/golang/go"${GO_VERSION}".linux-s390x.tar.gz
	chmod ugo+r go"${GO_VERSION}".linux-s390x.tar.gz
	sudo rm -rf /usr/local/go /usr/bin/go
	sudo tar -C /usr/local -xzf go"${GO_VERSION}".linux-s390x.tar.gz
	sudo ln -sf /usr/local/go/bin/go /usr/bin/
	sudo ln -sf /usr/local/go/bin/gofmt /usr/bin/
	sudo ln -sf /usr/bin/gcc /usr/bin/s390x-linux-gnu-gcc

  	make db-fetch-langs db-fetch-vuln-list
   	make build
    	make db-build
     	sudo cp /trivy-db/out/trivy.db /root/.cache/trivy/db/trivy.db
        chmod 644 /root/.cache/trivy/db/trivy.db
	export TRIVY_DB_FILE=./out/trivy.db
 
	wget https://github.com/aquasecurity/trivy/releases/download/v0.45.0/trivy_0.45.0_Linux-S390X.tar.gz
	tar -xf trivy_0.45.0_Linux-S390X.tar.gz
        chmod +x trivy
        sudo mv trivy /usr/bin
	echo "Executing trivy scanner"
	sudo trivy -q image --timeout 30m -f json ${image_name} > trivy_image_vulnerabilities_results.json
	sudo trivy -q image --timeout 30m -f cyclonedx ${image_name} > trivy_image_sbom_results.cyclonedx
 fi