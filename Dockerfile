# Use a lightweight, stable Linux base
FROM alpine:3.19

# Define Velero version as a variable for easy upgrades
ARG VELERO_VERSION=v1.14.0

# Install dependencies needed to fetch and extract the binary (and curl/bash for debugging)
RUN apk add --no-cache curl tar gzip bash

# Download the official Velero release matching your architecture (AMD64)
RUN curl -L https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz -o velero.tar.gz \
    && tar -xvf velero.tar.gz \
    && mv velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/velero \
    && rm -rf velero.tar.gz velero-${VELERO_VERSION}-linux-amd64

# Create a home directory for the container user
WORKDIR /root

# Set the default entrypoint explicitly to the system-path executable
ENTRYPOINT ["/usr/local/bin/velero"]

# Default argument if none are provided
CMD ["--help"]
