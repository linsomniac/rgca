#!/bin/bash
#
#  rgca pre script

#  Available environment variables:
#  Everything in examples/config.ini
#  FILES: A spavce separated list of all generated files (cert and key)
#  COMMAND: "CERT_NEW"
#  STAGE: "PRE" or "POST"

if [ "$COMMAND" = "CERT_NEW" ]; then
  echo "Do new certificate logic here"
fi
