# Jenkins, Docker-in-Docker, WebHook <br>

Thank you to Dawei for introducing Jenkins CI/CD with Docker-in-Docker <br>
and GitHub Webhooks concept to automate above pipeline

The repository for this project is located [here](https://github.com/FariusGitHub/Example_Webpage).

# Instructions

Follow these steps to set up and run the project:

1.  **Install Terraform**

    Ensure Terraform is installed on your system. If not, you can follow the official [Terraform Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

2.  **Provision resources**

    Below command will run main.tf that provision necessary EC2 to host Jenkins.

```sh
terraform init
terraform plan
terraform apply --auto-approve
```

3.  **Follow along the subsequent steps below to complete the entire project.**

In previous 3 blogs about Jenkins we might learn about the following

* Maven and Gradle in Jenkins (https://medium.com/p/239f2db88773/edit)
* Jenkins Command Line Interface (https://medium.com/p/69b2bc0adc3e/edit)
* Jenkins Docker Compose Orchestration (https://medium.com/p/69b2bc0adc3e/edit)

Here we will elaborate more automation when changes made to pipeline script and the deployment will be triggered. We will introduce docker-in-docker concept to enable Jenkins has proper access to its own Docker Hub.


![](/images/01-image01.png)
<center>
  Fig 01: Switching from Container A to Container B that inherited all attributes from Container A + docker.io
</center>
<br>

First, let's see below as a necessary install during an EC2 setup found in appendix below. It is install-packages.sh file to setup EC2 with docker.

```sh
#!/bin/bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# make sure docker is started
sudo service docker start

# add ubuntu to the docker group
sudo usermod -aG docker ubuntu
```

To know docker is working, do the following or keep exit/enter terminal
```sh
ubuntu@ip-10-2-254-152:~$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
ubuntu@ip-10-2-254-152:~$
```

Herewith all details about docker if everything were installed properly.

```sh
ubuntu@ip-10-2-254-152:~$ docker version
Client: Docker Engine - Community
 Version:           24.0.7
 API version:       1.43
 Go version:        go1.20.10
 Git commit:        afdd53b
 Built:             Thu Oct 26 09:07:41 2023
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          24.0.7
  API version:      1.43 (minimum version 1.12)
  Go version:       go1.20.10
  Git commit:       311b9ff
  Built:            Thu Oct 26 09:07:41 2023
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.6.26
  GitCommit:        3dd1e886e55dd695541fdcd67420c2888645a495
 runc:
  Version:          1.1.10
  GitCommit:        v1.1.10-0-g18a0cb0
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0

ubuntu@ip-10-2-254-152:~$ docker run -p 8080:8080 -p 50000:50000 -d -v jenkins_home://var/jenkins_home jenkins/jenkins:lts
Unable to find image 'jenkins/jenkins:lts' locally
lts: Pulling from jenkins/jenkins
90e5e7d8b87a: Pull complete 
f46e108600e7: Pull complete 
67ee1cced2cb: Pull complete 
3dfb3d6cb44e: Pull complete 
46014cb180c0: Pull complete 
20f6ee282779: Pull complete 
f8ee3f626f99: Pull complete 
b636b23fb8d6: Pull complete 
a3ffaaf08d83: Pull complete 
fc8874a22e0d: Pull complete 
eef971f7a8d4: Pull complete 
fb46046a6402: Pull complete 
Digest: sha256:186a48ae298e34a21b27fe737bf0a854c3e73421ce858c4d40c403802589e23f
Status: Downloaded newer image for jenkins/jenkins:lts
3a70bf47be93251f737e94124e5a66d975f57f98c2d43a6f19bd225680c9026a

ubuntu@ip-10-2-254-152:~$ docker images
REPOSITORY        TAG       IMAGE ID       CREATED       SIZE
jenkins/jenkins   lts       41e27c2a574b   4 weeks ago   486MB

ubuntu@ip-10-2-254-152:~$ docker ps -a
CONTAINER ID   IMAGE                 COMMAND                  CREATED          STATUS          PORTS                                                                                      NAMES
3a70bf47be93   jenkins/jenkins:lts   "/usr/bin/tini -- /u…"   28 seconds ago   Up 25 seconds   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp, 0.0.0.0:50000->50000/tcp, :::50000->50000/tcp   tender_sutherland

ubuntu@ip-10-2-254-152:~$
```

In this case 3a70bf47be93 is the container we are going to use now, but Jenkins won't rely on this container to access Docker. Now let's go inside it and get the jenkins Web UI password like below. Where the IP is 3.85.44.76:8080

![](/images/01-image02.png)
<center>
  Fig 02: Example of EC2 instance
</center>
<br>

```sh
ubuntu@ip-10-2-254-152:~$ docker exec -it 3a70bf47be93 /bin/bash

jenkins@3a70bf47be93:/$ cat /var/jenkins_home/secrets/initialAdminPassword
8af7c6b65a7f4f4e8972d7fa2928e104

jenkins@3a70bf47be93:/$
```

![](/images/01-image03.png)
<center>
  Fig 03: Example of Jenkins Web UI
</center>
<br>

Subsequent windows will ask whether you would like to chance the password. I prefer not and in case I forget the password I use the old one.
In our case the Jenkins web UI access is http://35.173.177.42:8080

![](/images/01-image04.png)
<center>
  Fig 04: When applied immediately, Jenkins not ready to deploy Docker. See a technique below to troubleshoot.
</center>
<br>

## ENABLING MAVEN IN JENKINS <br>
There 3 java compiler in Jenkins: Maven, Gradle, Ant. Let's just pick Maven, give it a name, apply & save. Jenkins java compiler is now linked to Maven.

![](/images/01-image05.png)
<center>
  Fig 05: Example of Maven Setup
</center>
<br>

## Installing Node.js and Python3 in Jenkins <br>
Let's go back to the terminal pointing to container id 3a70bf47be93 again

```sh
docker exec -u root -it 3a70bf47be93 /bin/bash
```

and running few command below
```sh
apt update
apt install -y nodejs
apt install -y npm
node -v
npm -v
exit
```

Above process will take couple minutes. At the end it will show v18.19.0 and 9.2.0 for example as values of node version number and npm version.

## Mounting Docker runtime into Jenkins Container (Docker in Docker) <br>
First we will stop the current container
```sh
ubuntu@ip-10-2-254-152:~$ docker stop 3a70bf47be93
3a70bf47be93
```
Then we will do another command below. This command mounts volume jenkins_home, directory of docker.sock to that of Jenkins container in order to allows Docker commands within the container to communicate with the Docker daemon on the host. We should see something like below.
```sh
ubuntu@ip-10-2-254-152:~$ docker run -p 8080:8080 -p 50000:50000 -d -v jenkins_home://var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins/jenkins:lts
83d800b93e07e7086911ea4044938c1b9a5a815b8e0bbf5ef6d6678dc1f029b2
ubuntu@ip-10-2-254-152:~$ docker ps -a

CONTAINER ID   IMAGE                 COMMAND                  CREATED          STATUS                            PORTS                                                                                      NAMES
83d800b93e07   jenkins/jenkins:lts   "/usr/bin/tini -- /u…"   35 seconds ago   Up 34 seconds                     0.0.0.0:8080->8080/tcp, :::8080->8080/tcp, 0.0.0.0:50000->50000/tcp, :::50000->50000/tcp   eager_cartwright
3a70bf47be93   jenkins/jenkins:lts   "/usr/bin/tini -- /u…"   24 minutes ago   Exited (143) About a minute ago                                                                                              tender_sutherland
```

`-v jenkins_home://var/jenkins_home` means
 It mounts the container "/var/jenkins_home" directory to the host machine
 "jenkins_home" directory. This allows persisting Jenkins data even if
the container is stopped or removed.

`-v /var/run/docker.sock:/var/run/docker.sock` means
 It mounts the host machine's Docker socket to the container's Docker socket. 
This allows the container to communicate with the Docker daemon on the
host machine. <br>

This time we don't have to initialize a Jenkins container. All the old data is stored in Jenkins_home volume and we attached it to a new container. <br>

Now try to access that new container 83d800b93e07.

```sh
docker exec -it -u root 83d800b93e07 /bin/bash
```

and install Docker client in order to run Docker commands in container. Always remember to run apt-get update to avoid error. Process below may take few a minutes to complete and change permission in order to access it and exit.

```sh
apt-get update
apt-get install -y docker.io
chmod 666 /var/run/docker.sock
exit
```

Access to the docker as Jenkins user

```sh
docker exec -it 83d800b93e07 /bin/bash
```

and do a quick test to see if docker command work in the Jenkins container

```
docker ps
```

```sh
ubuntu@ip-10-2-254-197:~$ docker exec -it 83d800b93e07 /bin/bash

jenkins@83d800b93e07:/$ docker ps
CONTAINER ID   IMAGE                 COMMAND                  CREATED         STATUS         PORTS                                                                                      NAMES
83d800b93e07   jenkins/jenkins:lts   "/usr/bin/tini -- /u…"   4 minutes ago   Up 4 minutes   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp, 0.0.0.0:50000->50000/tcp, :::50000->50000/tcp   romantic_hoover
```

Docker was installed at 83d800b93e07. Both 3a70bf47be93 & 83d800b93e07 support http://3.85.44.76:8080/. Switching between them require re-login but the projects and everything else inside Jenkins UI will not be deleted.

![](/images/01-image06.png)
<center>
  Fig 06: Activate back 3a70bf47be93 would make http://3.85.44.76:8080/ running without Docker
</center>
<br>

## Installing Python, Pip and Venv <br>
Make sure you exit from the session above and log back in as root as below

```sh
devops@msi:~$ docker exec -it -u root 83d800b93e07 /bin/bash
root@6de04cd8225f:/# apt-get update
apt install -y python3 python3-pip python3-venv
```

```sh
root@83d800b93e07:/# python3 --version
Python 3.11.2
root@54676282696e:/#
```

## Creating Credentials in Jenkins <br>
In case that you have been logout, see password above assuming you did not change it before. Now, let's go to Dashboard → Manage Jenkins → Credentials (under Security) → Triangle beside global → Add credentials

![](/images/01-image07.png)
<center>
  Fig 07: How to add Credentials
</center>
<br>

You need to get token (which is called password below) from your GitHub

![](/images/01-image08.png)
<center>
  Fig 08: Example of Adding GitHub credentials 
</center>
<br>

and you should see something like below. Remember it is your GitHub token not your GitHub password, unless it won't work.

![](/images/01-image09.png)
<center>
  Fig 09: Result after Adding GitHub credentials 
</center>
<br>


## Building a pipeline <br>
Go to Dashboard → New Item → Enter name → Choose Pipeline. We use below repo for this pipeline https://github.com/FariusGitHub/Example_Webpage Scroll down to Pipeline Section → Click on Pipeline script → Choose Pipeline script from SCM → Click SCM → Choose Git → Enter your Repository URL → Choose your Credential <br><br>
See below highlights on what to do subsequently, click apply and save.

![](/images/01-image10.png)
<center>
  Fig 10: Example of Adding New Pipeline with Git url 
</center>
<br>

## Jenkinsfile <br>
Basically Jenkinsfile tells Jenkins what to do in Groovy syntax. There are two kinds of pipelines for Jenkins, one is called scripted pipeline, the other one is declarative pipeline. <br>
1. Scripted Pipeline: Most functionality provided by the Groovy language is made available to Scripted Pipeline, which means it can be a very expressive and flexible tool and it is ideal choice for power-users with complex requirements.
2. Declarative Pipeline: Presents a more simplified and opinionated syntax. It must be enclosed with a pipeline block and it has a strict and pre-defined structure. It is friendly for beginners.

We are going to use Declarative pipeline as it is easy to get started. All we need to do is converting our workflow into code in Groovy syntax. <br>

Jenkinsfile Reference: https://www.jenkins.io/doc/book/pipeline/syntax/ <br><br>
In order to enable below, credential ftjioesman has to be created first.


![](/images/01-image11.png)
<center>
  Fig 11: Example of Adding Docker Hub credentials 
</center>
<br>

![](/images/01-image12.png)
<center>
  Fig 12: Result of Adding Docker Hub credentials 
</center>
<br>

Once all login were setup we can run simple Jenkins Pipeline below. I started one by one from prepare, test, build, deploy stage progressively so we can see the green blocks below added as I add one stage for each build.


![](/images/01-image13.png)
<center>
  Fig 13: Example of Jenkins Pipeline Stage View 
</center>
<br>

## Triggering Pipeline Jobs Automatically with Github Webhooks <br>
On GitHub Page, go to the repo, setting and WebHook and add the EC2 url like below with /github-webook/ endings like below

![](/images/01-image14.png)
<center>
  Fig 14: Web Hook Step 1 → add EC2 url in GitHub repo 
</center>
<br>

![](/images/01-image15.png)
<center>
  Fig 15: Web Hook Step 2 → Review the saved url web hook 
</center>
<br>

on Jenkins side we need to tweak the configure, Build Triggers as follow

![](/images/01-image16.png)
<center>
  Fig 16: Web Hook Step 3 → Check GitHub hook trigger from Jenkins Web UI 
</center>
<br>

As soon as we finished making some changes in GitHub Repo above, in this case I disabled one stage the Jenkins UI starts to show some activity below. GitHub Web hook required port 80 and 443 opened which we did earlier.

![](/images/01-image17.png)
<center>
  Fig 17: Example of Automatic Pipeline Trigger when GitHub was edited 
</center>
<br>

![](/images/01-image18.png)
<center>
  Fig 18: Example of Automated Update Completion 
</center>
<br>

## SUMMARY

![](/images/01-image19.png)
<center>
  Fig 20: Switching from Container A to Container B and vice versa
</center>
| Left columns  | Container A                 | Container B
| ------------- |:----------------------------|:-------------
| linux command | docker stop container_B_id  | docker stop container_A_id
|               | docker start container_A_id | docker start container_B_id
| docker.io     | not installed               | installed through root (DinD)
| docker ps     | permission denied           | list of active container shown

Docker in Docker (DinD) is not necessarily running Docker inside another Docker.<br>
In this case, only one container exist at a time. In simple terms, <br>
Docker Inside Docker involves running Docker within a Docker container. <br>
Instead of interacting with the host's Docker daemon, a new Docker engine is spawned within a container, <br>
providing an isolated environment for managing containers and images.
