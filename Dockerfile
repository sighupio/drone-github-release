# Copyright (c) 2021 SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

FROM plugins/github-release:latest as binary

FROM debian:buster
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=binary /bin/drone-github-release /bin/drone-github-release
ENTRYPOINT [ "/bin/drone-github-release" ]
