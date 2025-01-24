ARG ATLANTIS_VERSION=v0.22.3
FROM ghcr.io/runatlantis/atlantis:${ATLANTIS_VERSION}

USER root

WORKDIR /

# for tflint
COPY .tflint.hcl /home/atlantis
# for tfsec
COPY tfsec_config.yaml /etc/tfsec_config.yaml

# for custom authorized users
COPY *users /home/atlantis

# For atlantis github app. This can be replaced with an environment variable.
COPY atlantis-app-key.pem /home/atlantis

RUN chown root:atlantis .tflint.hcl \
    && chown root:atlantis atlantis-app-key.pem \
    && chmod 444 .tflint.hcl \
    && chown root:atlantis users \
    && chmod 444 users

# checkov requires python
# deploying lambdas requires python
RUN apk del gcompat || true \
    && apk --no-cache add \
        'aws-cli~=2' \
        'curl~=8.8' \
        'jq~=1.7' \
        'groff~=1.23' \
        'python3' \
        'py3-pip' \
        'py3-virtualenv' \
    && rm -rf /var/cache/apk/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG CHECKOV_VERSION=1.0.770
ENV CHECKOV_VERSION=${CHECKOV_VERSION}

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py \
    && rm get-pip.py \
    && python3 -m pip install --user \
      checkov==${CHECKOV_VERSION}

ENV PATH="/home/atlantis/.local/bin:${PATH}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# https://github.com/aquasecurity/tfsec/releases
ARG TFSEC_VERSION=1.28.6
ENV TFSEC_VERSION=${TFSEC_VERSION}

RUN curl -sL https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64 -o tfsec-linux-amd64 \
    && curl -sL https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec_checksums.txt -o tfsec_checksums.txt \
    && grep tfsec-linux-amd64 tfsec_checksums.txt | sha256sum -c - \
    && rm tfsec_checksums.txt \
    && mv tfsec-linux-amd64 /usr/local/bin/tfsec \
    && chmod +x /usr/local/bin/tfsec

# https://github.com/dineshba/tf-summarize/releases
ARG TFSUMMARIZE_VERSION=0.3.10
ENV TFSUMMARIZE_VERSION=${TFSUMMARIZE_VERSION}

RUN curl -sL https://github.com/dineshba/tf-summarize/releases/download/v${TFSUMMARIZE_VERSION}/tf-summarize_linux_amd64.tar.gz -o tf-summarize_linux_amd64.tar.gz \
    && curl -sL https://github.com/dineshba/tf-summarize/releases/download/v${TFSUMMARIZE_VERSION}/tf-summarize_SHA256SUMS -o tf-summarize_SHA256SUMS \
    && grep tf-summarize_linux_amd64.tar.gz tf-summarize_SHA256SUMS | sha256sum -c - \
    && rm tf-summarize_SHA256SUMS \
    && tar xvfz tf-summarize_linux_amd64.tar.gz tf-summarize -C /usr/local/bin \
    && rm tf-summarize_linux_amd64.tar.gz \
    && chmod +x /usr/local/bin/tf-summarize

# https://github.com/infracost/infracost
ARG INFRACOST_VERSION=0.10.38
ENV INFRACOST_VERSION=${INFRACOST_VERSION}
RUN \
    curl -sL "https://github.com/infracost/infracost/releases/download/v${INFRACOST_VERSION}/infracost-linux-amd64.tar.gz" -o infracost-linux-amd64.tar.gz \
    && curl -sL "https://github.com/infracost/infracost/releases/download/v${INFRACOST_VERSION}/infracost-linux-amd64.tar.gz.sha256" -o infracost_SHA256SUMS \
    && grep infracost-linux-amd64.tar.gz infracost_SHA256SUMS | sha256sum -c - \
    && rm infracost_SHA256SUMS \
    && tar xvfz infracost-linux-amd64.tar.gz \
    && rm infracost-linux-amd64.tar.gz \
    && mv infracost-linux-amd64 /usr/bin/infracost

# https://github.com/tmccombs/hcl2json
ARG HCL2JSON_VERSION=0.6.3
ENV HCL2JSON_VERSION=${HCL2JSON_VERSION}
RUN \
    curl -sL "https://github.com/tmccombs/hcl2json/releases/download/v${HCL2JSON_VERSION}/hcl2json_linux_amd64" -o hcl2json_linux_amd64 \
    && chmod +x hcl2json_linux_amd64 \
    && mv hcl2json_linux_amd64 /usr/bin/hcl2json

# https://github.com/transcend-io/terragrunt-atlantis-config
ARG TERRAGRUNT_ATLANTIS_CONFIG_VERSION=1.16.0
ENV TERRAGRUNT_ATLANTIS_CONFIG_VERSION=${TERRAGRUNT_ATLANTIS_CONFIG_VERSION}
ENV TERRAGRUNT_ATLANTIS_CONFIG_NAME=terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION}_linux_amd64
RUN \
    curl -sL "https://github.com/transcend-io/terragrunt-atlantis-config/releases/download/v${TERRAGRUNT_ATLANTIS_CONFIG_VERSION}/${TERRAGRUNT_ATLANTIS_CONFIG_NAME}.tar.gz" -o ${TERRAGRUNT_ATLANTIS_CONFIG_NAME}.tar.gz \
    && curl -sL "https://github.com/transcend-io/terragrunt-atlantis-config/releases/download/v${TERRAGRUNT_ATLANTIS_CONFIG_VERSION}/SHA256SUMS" -o terragrunt-atlantis-config_SHA256SUMS \
    && grep ${TERRAGRUNT_ATLANTIS_CONFIG_NAME}.tar.gz terragrunt-atlantis-config_SHA256SUMS | sha256sum -c - \
    && rm terragrunt-atlantis-config_SHA256SUMS \
    && tar xvfz ${TERRAGRUNT_ATLANTIS_CONFIG_NAME}.tar.gz \
    && chmod +x ${TERRAGRUNT_ATLANTIS_CONFIG_NAME}/${TERRAGRUNT_ATLANTIS_CONFIG_NAME} \
    && mv ${TERRAGRUNT_ATLANTIS_CONFIG_NAME}/${TERRAGRUNT_ATLANTIS_CONFIG_NAME} /usr/bin/terragrunt-atlantis-config \
    && rm ${TERRAGRUNT_ATLANTIS_CONFIG_NAME}.tar.gz \
    && rm -rf ${TERRAGRUNT_ATLANTIS_CONFIG_NAME}

# https://github.com/gruntwork-io/terragrunt
ARG TERRAGRUNT_VERSION=0.54.12
ENV TERRAGRUNT_VERSION=${TERRAGRUNT_VERSION}
RUN \
    curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" -o terragrunt_linux_amd64 \
    && curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/SHA256SUMS" -o terragrunt_SHA256SUMS \
    && grep terragrunt_linux_amd64 terragrunt_SHA256SUMS | sha256sum -c - \
    && rm terragrunt_SHA256SUMS \
    && chmod +x terragrunt_linux_amd64 \
    && mv terragrunt_linux_amd64 /usr/bin/terragrunt

WORKDIR /

USER atlantis

COPY policies/terraform-code /opt/policies/terraform-code
