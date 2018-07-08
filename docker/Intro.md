# What is Docker?
Docker is based on the idea of containerization: operating system level virtualization; an isolated userspace on top of OS kernel. Containers are self-contained packages and include everything needed to run it.

Docker itself is the application, that using Linux Containers (or Hyper-V in case of Windows) helps to develop, ship and run applications.

Basic intros from [independant author](https://devopscube.com/what-is-docker/) and [Docker Inc](https://www.docker.com/what-container)

## Docker architecture
Docker is a client-server solution which consists of:
1. Docker daemon - the server, which listens to clients REST commands and manages Docker objects: _images_, _containers_, _volumes_, _networks_
2. Docker client - command-line tool to send commands (e.g. `docker run`) as REST requests to the Docker Daemon.

Client can be installed on the same OS with the Docker daemon or communicate with a remote one.

### Docker images
An _image_ is a **read-only** template with instructions for creating a Docker _container_. Often an image is based on another image with some additional customization. 

### Docker container
A _container_ is a runnable instance of an _image_. 

You can create, start, stop, move, or delete a _container_ using the Docker API or CLI. You can connect a container to one or more _networks_, attach storage (_volume_) to it, or even create a new _image_ based on its current state.

### Docker registries
Docker _registry_ is a store of Docker _images_. Registries may be public, like **Docker Hub**, or private (on premise, Azure Container Registry, Amazon Elastic Container Registry, etc).

For example, `docker pull` or `docker push` commands work against specified registry.

More details about the platform, architecture, and underlying technologies: https://docs.docker.com/engine/docker-overview

# Install docker
Follow instructions for your platform: https://docs.docker.com/install/

When instalation is complete run `docker info` to get details about installed application and `docker run hello-world` to verify docker daemon is up and running.

# Tutorials
1. Get started https://docs.docker.com/get-started/
2. Detailed set of training courses https://training.play-with-docker.com/

# Cheat sheet
Each command may be used with `--help` parameter to get support.

Note, *image_id* or *container_id* may consist of only first few characters of id, that uniquely identify object. For example, image with id *c5355f8853e4* may be removed with `docker image rm c53` command

* `docker --help`
	* `docker info` - display system-wide information (system version, installed plugins, containers, images, etc)
* `docker image --help`
	* `docker pull {image_name}` - pulls *image_name* from Container Registry
	* `docker push {image_name}` - pushes *image_name* to Container Registry
	* `docker image inspect {image_name}` - detailed information about the image
	* `docker image ls` - lists all local (cached) images
	* `docker image rm {image_id}` - removes image with id=*image_id* from local image store. 
	* `docker image prune` - removes unused images
* `docker container --help`
	* `docker container run` - executes a command inside a **new** container instance.
	* `docker container start {container_id}` and `docker container stop {container_id}` - starts or stops container with specified id.
	* `docker container inspect {container_id}` - detailed information about the container
	* `docker container ls` - lists running containers. Add `--all` parameter to show even stopped containers
	* `docker container rm {container_id}` - removes **stopped** container with id=*container_id*.
	* `docker container logs {container_id}` - fetches logs of the container
	* `docker container exec {container_id} {command}` - executes {command} within **running** container with id=*container_id*
	* `docker container stats` - displays a live stream of container(s) statistics (CPU, MEM usages, I/O ops). Also available with `--no-stream` parameter
* `docker volume --help`
	* `docker volume create {volume_name}` - creates a volume
	* `docker volume inspect {volume_name}` - displays detailed information on one or more volumes (using comma separator)
	* `docker volume ls` - lists volumes
	* `docker volume prune` - removes all unused local volumes
 	* `docker volume rm {volume_name}` - removes one or more volumes (using comma separator)
	
# Further reading
[Operating system level virtualization](https://en.wikipedia.org/wiki/Operating-system-level_virtualization) - Wiki entry explaining virtualization provided at the user space by operating systems.

[Linux namespaces](https://en.wikipedia.org/wiki/Linux_namespaces) - Wiki entry on how namespaces - which Docker relies on - work in Linux and what kind of isolation they provide.

[Windows Containers](https://docs.microsoft.com/en-us/virtualization/windowscontainers/about/) - MSDN articles on windows containers.
