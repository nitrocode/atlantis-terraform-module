ARG ATLANTIS_VERSION=v0.22.1
FROM ghcr.io/runatlantis/atlantis:${ATLANTIS_VERSION}

WORKDIR /home/atlantis

# https://github.com/sgerrand/alpine-pkg-glibc/releases
ARG GLIBC_VERSION=2.34-r0
ENV GLIBC_VERSION=${GLIBC_VERSION}

# install glibc compatibility for alpine and awscliv2
RUN apk del gcompat || true \
    && apk --no-cache add \
        'binutils~=2.39' \
        'curl~=7.87' \
        'jq~=1.6' \
        'groff~=1.22' \
        'gpg~=2.2' \
        'gpg-agent~=2.2' \
    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk \
    && apk add --no-cache --force-overwrite \
        glibc-${GLIBC_VERSION}.apk \
        glibc-bin-${GLIBC_VERSION}.apk \
        glibc-i18n-${GLIBC_VERSION}.apk \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8

ARG AWSCLI_VERSION=2.7.19
ENV AWSCLI_VERSION=${AWSCLI_VERSION}

RUN curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip -o awscliv2.zip \
    && curl -o awscliv2.sig https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip.sig \
    && gpg --import awscliv2.public.gpg.key \
    && gpg --verify awscliv2.sig awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
    && rm -rf awscliv2.zip awscliv2.sig awscliv2.public.gpg.key aws \
        /usr/local/aws-cli/v2/current/dist/aws_completer \
        /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/current/dist/awscli/examples \
        glibc-*.apk \
    && find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete \
    && apk --no-cache del \
        binutils \
        gpg \
        gpg-agent \
    && rm -rf /var/cache/apk/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://github.com/aquasecurity/tfsec/releases
ARG TFSEC_VERSION=1.27.6
ENV TFSEC_VERSION=${TFSEC_VERSION}

RUN curl -sL https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64 -o tfsec-linux-amd64 \
    && curl -sL https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec_checksums.txt -o tfsec_checksums.txt \
    && grep tfsec-linux-amd64 tfsec_checksums.txt | sha256sum -c - \
    && rm tfsec_checksums.txt \
    && mv tfsec-linux-amd64 /usr/local/bin/tfsec \
    && chmod +x /usr/local/bin/tfsec

# https://github.com/dineshba/tf-summarize/releases
ARG TFSUMMARIZE_VERSION=0.2.3
ENV TFSUMMARIZE_VERSION=${TFSUMMARIZE_VERSION}

RUN curl -sL https://github.com/dineshba/tf-summarize/releases/download/v${TFSUMMARIZE_VERSION}/tf-summarize_linux_amd64.zip -o tf-summarize_linux_amd64.zip \
    && curl -sL https://github.com/dineshba/tf-summarize/releases/download/v${TFSUMMARIZE_VERSION}/tf-summarize_SHA256SUMS -o tf-summarize_SHA256SUMS \
    && grep tf-summarize_linux_amd64.zip tf-summarize_SHA256SUMS | sha256sum -c - \
    && rm tf-summarize_SHA256SUMS \
    && unzip tf-summarize_linux_amd64.zip tf-summarize -d /usr/local/bin \
    && rm tf-summarize_linux_amd64.zip \
    && chmod +x /usr/local/bin/tf-summarize

# https://github.com/infracost/infracost
ARG INFRACOST_VERSION=0.10.14
ENV INFRACOST_VERSION=${INFRACOST_VERSION}

RUN \
  curl -sL "https://github.com/infracost/infracost/releases/download/v${INFRACOST_VERSION}/infracost-linux-amd64.tar.gz" -o infracost-linux-amd64.tar.gz \
  && curl -sL "https://github.com/infracost/infracost/releases/download/v${INFRACOST_VERSION}/infracost-linux-amd64.tar.gz.sha256" -o infracost_SHA256SUMS \
  && grep infracost-linux-amd64.tar.gz infracost_SHA256SUMS | sha256sum -c - \
  && rm infracost_SHA256SUMS \
  && tar xvfz infracost-linux-amd64.tar.gz \
  && rm infracost-linux-amd64.tar.gz \
  && mv infracost-linux-amd64 /usr/bin/infracost

# install tflint
ARG TFLINT_VERSION=0.24.1
ENV TFLINT_VERSION=${TFLINT_VERSION}

RUN curl -sL https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip -o /tmp/tflint.zip \
    && unzip /tmp/tflint.zip -d /usr/local/bin/ \
    && rm /tmp/tflint.zip

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

# for checkov, python must be installed
RUN apk add --no-cache \
    'python3>3.8.5-r0' \
    && rm -rf /var/cache/apk/*

USER atlantis

ARG CHECKOV_VERSION=1.0.770
ENV CHECKOV_VERSION=${CHECKOV_VERSION}

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py \
    && rm get-pip.py \
    && python3 -m pip install --user \
      checkov==${CHECKOV_VERSION}

ENV PATH="/home/atlantis/.local/bin:${PATH}"
