# Test Execution Prerequisites

- A `app-toolkit-values.yaml` file containing the following information:

  ```yaml
  contour:
    envoy:
      service:
        type: ClusterIP
      hostPorts:
        enable: true

  knative_serving:
    domain:
      type: real
      name: 127-0-0-1.sslip.io

  kpack:
    # name of registry secret where build artifacts are stored
    kp_default_repository: [DEFAULT_REGISTRY_URL]
    kp_default_repository_username: [DEFAULT_REGISTRY_USERNAME]
    kp_default_repository_password: [DEFAULT_REGISTRY_PASSWORD]
  ```

  Where:
  - `DEFAULT_REGISTRY_URL` is a valid OCI registry to store kpack images, like `https://index.docker.io/v1/`
  - `DEFAULT_REGISTRY_USERNAME` and `DEFAULT_REGISTRY_PASSWORD` are the credentials for the specified registry.

After creating the file with the required fields, you can start the actual test execution with this command: `go run app-toolkit-test.go`
