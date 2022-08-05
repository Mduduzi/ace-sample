#This Docker file is based on https://github.com/ot4i/ace-docker


#based on base image with ACE Developer edition (see Dockerfile in ace-base-image directory)
#note: instructions in base Dockerfile could be here, but base image was created so that ACE Developer Edition
#is not downloaded every time this image is built (see Dockerfile-with-ace-install).
FROM kazhar/ace-sample:base

ENV LICENSE=accept
ENV ACE_WORKING_DIR=/home/aceuser/ace-server

RUN /opt/ibm/ace-12/ace make registry global accept license deferred \
    && useradd --uid 1001 --create-home --home-dir /home/aceuser --shell /bin/bash -G mqbrkrs aceuser \
    && su - aceuser -c "export LICENSE=accept && . /opt/ibm/ace-12/server/bin/mqsiprofile && mqsicreateworkdir $ACE_WORKING_DIR" \
    && echo ". /opt/ibm/ace-12/server/bin/mqsiprofile" >> /home/aceuser/.bashrc

WORKDIR /home/aceuser

# Add required license as text file in Licenses directory (GPL, MIT, APACHE, Partner End User Agreement, etc)
COPY licenses/ ./licenses/

# add integration application sources
COPY ace-sample-app/ ./src/

COPY start.sh .

# Expose ports.  7600 is admin port, 7800 is HTTP port.
EXPOSE 7600 7800

#change ownership of all files in /home/aceuser directory
RUN chown -R 1001 /home/aceuser

#sets the directory and file permissions to allow users in the root group to access them
#required by OpenShift
RUN chgrp -R 0 /home/aceuser && chmod -R g=u /home/aceuser

# run as aceuser
USER 1001

CMD ["/bin/sh","start.sh"]
