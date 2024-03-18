FROM ghcr.io/terraform-linters/tflint:v0.50.3
ADD .tflint.hcl .
RUN tflint --init
