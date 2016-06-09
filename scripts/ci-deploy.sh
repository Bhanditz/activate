#!/bin/bash -xe

# upload all artifacts from a single worker
gsutil cp -r -a public-read binaries/* gs://dl.itch.ovh/activate/
