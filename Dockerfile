FROM scratch
EXPOSE 8080
ENTRYPOINT ["/test-custom-bp-test"]
COPY ./bin/ /