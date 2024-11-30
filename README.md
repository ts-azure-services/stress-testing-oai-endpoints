This repo contains a number of workflows and scripts to stress test Azure OpenAI endpoints, both individually and through an APIM
instance. Most of the workflow and steps are captured in the `Makefile` and should be followed sequentially. This leverages
`locust` as a testing framework to simulate concurrent users, but also leverages batch approaches to hit the endpoints with load.
All this was tested on a Mac, though would work equally on any Unix-based machine. This also relies on several command-line tools like
`parallel` and `jq`. For reference, these tools are also available in the Azure Cloud shell by default, providing an easy
deployment option.

### Random Notes
- For the Azure OpenAI endpoints, this has leveraged the Global Standard deployment for gpt-4o. This can be customized as needed.
- This does not include setup of Application Insights or Log Analytics as part of the workflow.
- For most of the "batch" workflows, there is no logic to implement a backoff period. Limits should be understood considering the
  capacity of the endpoint and/or the logic in place (e.g. with APIM) to handle throttling.
- While on a Mac, to monitor CPU and memory usage, consider using `btop` (available through Homebrew). To determine the number of CPUs, run: `sysctl -n hw.ncpu`.
- Future build:
  - Inclusion of text embedding endpoints to test Azure Search workflows.

### References
- For the APIM tooling, leveraged this great [repo](https://github.com/Azure-Samples/AI-Gateway) to support setup and the custom APIM policy.
