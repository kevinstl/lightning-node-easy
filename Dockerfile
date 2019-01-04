FROM scratch
EXPOSE 8080
ENTRYPOINT ["/lightning-node-easy"]
COPY ./bin/ /