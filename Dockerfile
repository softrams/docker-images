FROM ghcr.io/terraform-linters/tflint:v0.50.3
ADD .tflint.hcl /.tflint.hcl
ENV TFLINT_CONFIG_FILE=/.tflint.hcl
ENV TFLINT_PLUGIN_DIR=/.tflint.d/plugins
RUN tflint --init
