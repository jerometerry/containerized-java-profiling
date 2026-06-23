aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

docker build --build-arg TARGETARCH=arm64 -t spring-boot-perf-repo .

docker tag spring-boot-perf-repo:latest <YOUR_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/spring-boot-perf-repo:latest

docker push <YOUR_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/spring-boot-perf-repo:latest