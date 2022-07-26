## Iterate through Docker configurations (See Assumption 1 for path convention)
for docker_build_context_relative_path in docker-builder/registry-repos/*; do
    ## Only iterate through directories
    [[ ! -d "$docker_build_context_relative_path" ]] && continue

    ## Get the absolute path for the Docker configurations (i.e., build context)
    docker_build_context_absolute_path=$(realpath "$docker_build_context_relative_path")

    local_image_name=test-image

    ## Local Docker image build
    docker build --no-cache --tag "${local_image_name}" "${docker_build_context_absolute_path}"

    ## Ensure that Trivy does NOT scan a cached image
    trivy image --reset
    
    ## Trivy scan
    ## (Into the future, we will make our blocking behavior more granular)
    ## If a vulnerability is found, Trivy will emit an exit code of 2
    trivy image --no-progress --severity CRITICAL,HIGH,MEDIUM --exit-code 2 --ignore-unfixed "${local_image_name}"
    vuln_result_code="$?"

    if [[ "$vuln_result_code" -eq 0 ]]; then
        echo "Docker image is in compliance with the security policy!"
        echo "Woo hoo!"
        echo "Starting scan of next Docker Image (if defined)"
        
        continue
    elif [[ "$vuln_result_code" -eq 2 ]]; then
        echo "This Docker image contains a vulnerability!"
        echo "Please fix!"
        echo "PATH: $docker_build_context_absolute_path"
        exit 1
    else
        echo "There was an unexpected error!"
        echo "Please reach out to the Security Team"
        exit 1
    fi
done
