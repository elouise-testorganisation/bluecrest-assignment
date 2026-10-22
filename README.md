# Bluecrest time-series app

## Prompts 
- This project was setup with the help of a free subscription to chatgpt using codex. 
- under /prompts the 5 major prompts have been included verbatim, which were used to generate the majority of features. The first two prompts can be directly linked to specific commits: 7d85784439402a09fe250987391ae222da716c14 and 7596dfc8316ab74c14d4705ed42fb810fe491bba , after which the direct mapping does not function well anymore. 
- This does not cover all work done with AI, but other parts were processes of debugging and refinement, via a mix of smaller AI prompts and manual modifications, configurations and tests. 

## Python application

- A small web app that reads a CSV of dates and values, tidies the data, and displays the selected time series as a chart and table.
- It handles common data issues, such as inconsistent column names and missing or malformed values, so a few bad cells do not stop the app.
- Automated tests check the data cleaning and confirm the app can still display usable data when the input is imperfect. This is a supporting part of the project, not its main focus.
- To view the app locally, run: 
```
brew install python@3.12     
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r src/app/requirements.txt
export BLUECREST_DATA_FILE="$PWD/src/data/data.csv"
python -m streamlit run src/app/app.py
```

## Kubernetes deployment

- The app is packaged for Kubernetes, with a deployment to run it, an internal service to connect to it, and a policy to restrict incoming network traffic. The data file is provided separately as a read-only configuration resource.
- Basic security measures are in place: the app runs as a non-root user with limited container privileges, a read-only filesystem, health checks, and defined CPU and memory limits. A private image registry uses credentials for image pulls.
- Development is deliberately lightweight, running one app instance with lower resource allocations. Production is configured for two instances with more resources.
- Public access is disabled by default. The network policy provides an additional layer of protection, but it is not a substitute for firewalls.
- There is no real hosting environment available to configure and validate the full network boundary. As a result, cloud and node firewalls, public routing, TLS, and other environment-level protections cannot yet be properly implemented and tested. These need to be addressed before exposing the app in a real production environment.

## GitHub Actions workflows

- **Tests:** Runs the automated Python tests. It can be started manually, called by another workflow, or requested on a pull request using a label.
- **Build image:** Builds the app's container image for common processor architectures and publishes it, along with its deployment package. Main builds are tagged for production; other builds are marked as development builds.
- **Development deploy:** Runs the tests and build, then deploys a non-production change to a temporary test namespace. It checks that the app starts and responds, then schedules the temporary namespace for cleanup.
- **Production deploy:** Runs the tests and build before deploying changes from the main branch to the production namespace. It checks that the app starts and responds.
- **Bootstrap infrastructure:** A manually started workflow that prepares the Kubernetes cluster resources and credentials needed for production deployment.
- The deployment workflows require a self-hosted runner connected to the Kubernetes environment and the appropriate registry credentials. Those prerequisites cannot be fully validated without the actual environment.

## Pull-request checks and future work

- The repository is set up so pull requests are checked before merging. The intended rules require four successful checks, while administrators can bypass the rules when necessary.
- The Terraform files are a future-work example showing how repository settings and branch protections could be managed as code from a separate repository. They have not been applied to the live repository.
- The Terraform example currently names only three required checks, so it needs to be reconciled with the intended four-check setup before it is used. Repository settings are currently managed manually.
