FROM plugins/github-release:latest as binary

FROM debian:buster
COPY --from=binary /bin/drone-github-release /bin/drone-github-release
ENTRYPOINT [ "/bin/drone-github-release" ]
