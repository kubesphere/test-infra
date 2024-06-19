# Copyright KubeSphere Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eux

# Enable docker buildx
export DOCKER_CLI_EXPERIMENTAL=enabled

CONTAINER_CLI=${CONTAINER_CLI:-docker}
# Use buildx for CI by default, allow overriding for old clients or other tools like podman
CONTAINER_BUILDER=${CONTAINER_BUILDER:-"build"}
GOLANG_IMAGE=${GOLANG_IMAGE:-"golang:1.21"}
HUB=${HUB:-"kubesphere"}
DATE=$(date +%Y-%m-%dT%H-%M-%S)
BRANCH=master
VERSION="${BRANCH}-${DATE}"

if [[ -z "${DRY_RUN:-}" ]]; then
  ${CONTAINER_CLI} ${CONTAINER_BUILDER} --push --target build_tools --build-arg "GOLANG_IMAGE=${GOLANG_IMAGE}" --build-arg "VERSION=${VERSION}" -t "${HUB}/build-tools:${VERSION}" .
  ${CONTAINER_CLI} ${CONTAINER_BUILDER} --push --target build_tools --build-arg "GOLANG_IMAGE=${GOLANG_IMAGE}" --build-arg "VERSION=${VERSION}" -t "${HUB}/build-tools:master-latest" .
else
  ${CONTAINER_CLI} ${CONTAINER_BUILDER} --load --target build_tools --build-arg "GOLANG_IMAGE=${GOLANG_IMAGE}" --build-arg "VERSION=${VERSION}" -t "${HUB}/build-tools:${VERSION}" .
  ${CONTAINER_CLI} ${CONTAINER_BUILDER} --load --target build_tools --build-arg "GOLANG_IMAGE=${GOLANG_IMAGE}" --build-arg "VERSION=${VERSION}" -t "${HUB}/build-tools:master-latest" .
fi
