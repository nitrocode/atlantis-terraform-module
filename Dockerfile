FROM runatlantis/atlantis:v0.16.1

WORKDIR /home/atlantis

ARG TFLINT_VERSION=0.24.1
ARG TFSEC_VERSION=0.37.3
ARG CHECKOV_VERSION=1.0.770
ARG AWSCLI_VERSION=1.19.4

RUN apk add --no-cache \
    'python3==3.8.5-r0' \
    'make==4.3-r0' \
    'jq==1.6-r1' \
    && rm -rf /var/cache/apk/*

# install tflint
RUN curl -L \
        https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip \
        -o /tmp/tflint.zip && unzip /tmp/tflint.zip -d /usr/local/bin/ && rm /tmp/tflint.zip

# install tfsec
RUN curl -L \
        https://github.com/liamg/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64 \
        -o /usr/local/bin/tfsec && chmod +x /usr/local/bin/tfsec

COPY .tflint.hcl /home/atlantis
COPY users /home/atlantis
COPY atlantis-app-key.pem /home/atlantis

RUN chown root:atlantis .tflint.hcl \
    && chown root:atlantis atlantis-app-key.pem \
    && chmod 444 .tflint.hcl \
    && chown root:atlantis users \
    && chmod 444 users

USER atlantis

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py \
    && rm get-pip.py \
    && python3 -m pip install --user \
      checkov==${CHECKOV_VERSION} \
      awscli==${AWSCLI_VERSION}

ENV PATH="/home/atlantis/.local/bin:${PATH}"
