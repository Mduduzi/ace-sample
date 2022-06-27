#This Docker file is based on https://github.com/ot4i/ace-docker
#Base ACE image, includes ACE developer edition

FROM registry.access.redhat.com/ubi8/ubi-minimal:8.6 as builder

RUN microdnf update && microdnf install util-linux curl tar

ARG USERNAME
ARG PASSWORD

#check latest ACE developer from http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/integration/
ARG DOWNLOAD_URL=http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/integration/12.0.4.0-ACE-LINUX64-DEVELOPER.tar.gz

RUN mkdir -p /opt/ibm/ace-12 \
    && if [ -z $USERNAME ]; then curl ${DOWNLOAD_URL}; else curl -u "${USERNAME}:${PASSWORD}" ${DOWNLOAD_URL}; fi | \
    tar zx --absolute-names \
    --exclude ace-12.0.*.0/tools \
    --exclude ace-12.0.*.0/server/tools/ibm-dfdl-java.zip \
    --exclude ace-12.0.*.0/server/tools/proxyservlet.war \
    --exclude ace-12.0.*.0/server/bin/TADataCollector.sh \
    --exclude ace-12.0.*.0/server/transformationAdvisor/ta-plugin-ace.jar \
    --strip-components 1 \
    --directory /opt/ibm/ace-12

#create base image
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.6

#update/install packages
RUN microdnf update && \ 
    microdnf install findutils util-linux curl tar && \
    microdnf clean all && \
    microdnf reinstall tzdata -y
# Note: force reinstall tzdata package to get zoneinfo files

#copy ACE from builder
COPY --from=builder /opt/ibm/ace-12 /opt/ibm/ace-12
