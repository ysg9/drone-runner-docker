#!/bin/bash
# build.sh - build script for drone pipeline
set -e
#set -x

APPNAME=drone-runner-docker
VER=${DRONE_TAG:-$(date '+%s')}
WORKDIR=${DRONE_WORKSPACE:-.}

rm -f go.mod go.sum
go mod init ${APPNAME}
go mod edit -replace github.com/docker/docker=github.com/docker/engine@v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible
go mod edit -replace github.com/containerd/containerd=github.com/containerd/containerd@v1.6.20
go mod edit -replace golang.org/x/text=golang.org/x/text@v0.11.0
go mod edit -replace golang.org/x/crypto=golang.org/x/crypto@v0.17.0
go mod edit -replace github.com/miekg/dns=github.com/miekg/dns@v1.1.55
#go mod edit -replace k8s.io/apiserver=k8s.io/apiserver@v0.26.0
go mod edit -replace github.com/opencontainers/runc=github.com/opencontainers/runc@v1.1.12
go mod edit -replace github.com/open-policy-agent/opa=github.com/open-policy-agent/opa@v0.55.0
go mod edit -replace github.com/emicklei/go-restful/v3=github.com/emicklei/go-restful/v3@v3.10.2
go mod edit -replace google.golang.org/grpc=google.golang.org/grpc@v1.59.0
go mod edit -replace go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc=go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc@v0.46.1
go mod edit -replace golang.org/x/net=golang.org/x/net@v0.18.0
go mod tidy

export GOPRIVATE=github.com/sgnus-it**
#export GOARCH=amd64

IFS=',' read -r -a PLATFORM <<< ${PLUGIN_PLATFORMS:-linux/amd64}
for p in "${PLATFORM[@]}"; do
  GOARCH=$(basename $p)
  GOOS=$(dirname $p)
  echo "building for ${GOOS}/${GOARCH}: ${VER}"
  if [[ ${DRONE:-} != "" ]]; then
    BIN="${APPNAME}_${VER}_${GOOS}_${GOARCH}"
  else
    BIN="${APPNAME}"
  fi
  EXE=$BIN
  if [[ $GOOS == "windows" ]]; then
    EXE="${BIN}.exe"
  fi
  GOOS=$GOOS GOARCH=$GOARCH go build \
    -trimpath \
    -ldflags "-X main.${VERVAR}=${VER}" -o ${WORKDIR}/${EXE}
  if [[ ${DRONE:-} != "" ]]; then
    zip -j ${WORKDIR}/${BIN}.zip ${WORKDIR}/${EXE}
  fi
  mv ${WORKDIR}/${EXE} ${WORKDIR}/${APPNAME}
done
echo "build complete"

### for dep scanning with nancy
go list -m all > go.list
echo "go.list generated"
go mod graph > go.graph
echo "go.graph generated"
cat go.graph

# whitelist CVE-2022-29153: consul issue; consul is not used.
echo CVE-2022-29153 > .nancy-ignore
# whitelist sonatype-2022-6522: false +ve
echo sonatype-2022-6522 >> .nancy-ignore
# whitelist CVE-2020-8561: k8s apiserver; not using k8s here.
# https://github.com/kubernetes/kubernetes/issues/104720
echo CVE-2020-8561 >> .nancy-ignore
