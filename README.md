
# BGP vs BGPsec Virtual Testbed

A virtual testbed used during my master thesis research on router overhead and convergence time in BGPsec compared to regular BGP.


This repository contains varius scripts and configuration files used to setup a Quagga (BGP) and QuaggaSRx (BGPsec) testbed for topologies with N amount of routers, ExaBGP(BGP) and BGPSEC-IO (BPGsec) are then used to inject N amount of prefixes.

For all router containers, their Docker stats, RIB convergence time and traffic has been made.

My full thesis can be found here:

The QuaggaSRx setup is based on earlier work of SIDN: https://github.com/SIDN/bgpsec-testbed/tree/main

## Directory layout
```
.
├── README.md
├── docker_images
│   ├── bgpsec-io
│   ├── exabgp
│   ├── quaggasrx-bgpsec
│   ├── quaggasrx
│   ├── srx_server
│   └── tal_share
├── scripts
│   ├── create-topologies
|   |    ├── linear-topology-bgp
|   |    └── linear-topology-bgpsec
│   └── experiment-1-scalability
|   |    ├── measuring-prefix-arrival
|   |    └── sending-prefix
└── topologies
    ├── configs
    ├── five_routers
    ├── ten_routers
    ├── fifteen_routers
    └── scripts
```

| Directory/File                                    | Description                                                                                                                                                                                                |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `bgpsec-testbed/scripts/create-topologies/linear-topology-bgp/generate_topology.py` | Script to generate linear Quagga (BGP) topologies with configuration.                                                                  |
| `bgpsec-testbed/scripts/create-topologies/linear-topology-bgpsec/generate_topology.py` | Script to generate linear QuaggaSRx (BGPsec) topologies with configuration.                                                            |
| `bgpsec-testbed/scripts/create-topologies/linear-topology-bgpsec/generate_asns.sh`  | Generates ASN mapping and cryptographic material for BGPsec routers.                                                                                               |
| `bgpsec-testbed/scripts/create-topologies/linear-topology-bgpsec/bgpsec_openssl.cnf`| OpenSSL configuration for generating BGPsec router certificates.                                                                        |
| `bgpsec-testbed/scripts/experiment-1-scalability/measuring-prefix-arrival/monitor_prefix_arrival.sh` | Script to monitor when prefixes arrive in the RIB and to capture traffic dumps, used for measuring convergence.                                                      |
| `bgpsec-testbed/scripts/experiment-1-scalability/measuring-prefix-arrival/prefixes.txt` | List of prefixes used for monitoring prefix arrival.                                                                                     |
| `bgpsec-testbed/scripts/experiment-1-scalability/sending-prefix/bgpspecio.conf`     | Configuration for BGPSEC-IO prefix injector.                                                                                            |
| `bgpsec-testbed/scripts/experiment-1-scalability/sending-prefix/exabgp.conf`        | Configuration for ExaBGP prefix injector.                                                                                               |
| `bgpsec-testbed/scripts/experiment-1-scalability/automate_runs.sh`                  | Automates test runs for either BGP or BGPsec, including docker restarts.                                                                |
| `bgpsec-testbed/scripts/experiment-1-scalability/generate_bgpsecio_conf.py`         | Script to generate BGPSEC-IO configuration files dynamically.                                                                           |
| `bgpsec-testbed/scripts/experiment-1-scalability/generate_exabgp_conf.py`           | Script to generate ExaBGP configuration files dynamically.                                                                              |
| `bgpsec-testbed/scripts/experiment-1-scalability/generate_prefix_list.py`           | Script to generate custom prefix lists for injection.                                                                                   |
| `bgpsec-testbed/scripts/experiment-1-scalability/prefixes.txt`                      | Prefix list used by both ExaBGP and BGPSEC-IO for injection.                                                                            |
| `bgpsec-testbed/scripts/experiment-1-scalability/run_full_test.sh`                  | Runs one full experiment iteration (injection + logging + monitoring).                                                                  |
| `bgpsec-testbed/scripts/experiment-1-scalability/start_docker_stats_logger.sh`      | Logs CPU/memory usage for all docker containers during the test run.                                                                    |
| `bgpsec-testbed/topologies/configs/kathara-quagga/`                                 | Configuration directory for Quagga-based BGP routers.                                                                                   |
| `bgpsec-testbed/topologies/configs/quaggasrx-bgpsec/`                               | Configuration directory for QuaggaSRx-based BGPsec routers.                                                                             |
| `bgpsec-testbed/topologies/configs/krill.conf`                                      | Configuration for Krill, the RPKI CA used in the testbed.                                                                               |
| `bgpsec-testbed/topologies/configs/routinator.conf`                                 | Configuration for Routinator, the RPKI validator cache.                                                                                 |
| `bgpsec-testbed/topologies/configs/rsyncd.conf`                                     | Configuration for the rsync daemon used in RPKI object sync.                                                                            |
| `bgpsec-testbed/topologies/configs/srx_server.conf`                                 | Main configuration file for the SRx-Server.                                                                                             |
| `bgpsec-testbed/topologies/configs/srxcryptopapi_server.conf`                       | Configuration for the SRxCryptoAPI server plugin.                                                                                       |
| `bgpsec-testbed/topologies/configs/srxcryptopapi.conf`                              | Configuration for SRxCryptoAPI cryptographic engine.                                                                                    |
| `bgpsec-testbed/topologies/five_routers/kathara-quagga/`                            | 5-router topology using Quagga for standard BGP.                                                                                        |
| `bgpsec-testbed/topologies/five_routers/quaggasrx-bgpsec/`                          | 5-router topology using QuaggaSRx for BGPsec.                                                                                           |
| `bgpsec-testbed/topologies/ten_routers/kathara-quagga/`                             | 10-router topology using Quagga for standard BGP.                                                                                       |
| `bgpsec-testbed/topologies/ten_routers/quaggasrx-bgpsec/`                           | 10-router topology using QuaggaSRx for BGPsec.                                                                                          |
| `bgpsec-testbed/topologies/fifteen_routers/kathara-quagga/`                         | 15-router topology using Quagga for standard BGP.                                                                                       |
| `bgpsec-testbed/topologies/fifteen_routers/quaggasrx-bgpsec/`                       | 15-router topology using QuaggaSRx for BGPsec.                                                                                          |
| `bgpsec-testbed/topologies/scripts/sign_csr.sh`                                     | Script to sign router Certificate Signing Requests (CSRs) using OpenSSL.                                                               |

## Running Topologies and Experiments

> ⚠️ Make sure all Bash scripts are executable (`chmod +x script.sh`) before running them.

---

### Phase 1: Creating Topologies

Navigate to the directory for either the Quagga (BGP) topology or the QuaggaSRx (BGPsec) topology.

#### QuaggaSRx (BGPsec)

1. **Generate ASN and Key Material**

   BGPSEC-IO relies on cryptographic key material to inject prefixes, so always generate N + 1 routers.  
   For example, for a 15-AS topology, run:

   ```bash
   ./generate_asns.sh 16
   ```

   This creates a directory called `key_setup`.

2. **Generate Topology**

   Run the Python script to generate the topology.  
   > ⚠️ This script relies on the `key_setup` directory, so do not move it before execution.

   ```bash
   python3 generate_topology.py
   ```

   This creates:
   - An `experiment_results` directory
   - A `router-configs` directory containing the Docker Compose snippet and router configurations

3. **Organize Router Configs**

   - Copy the config files from the first N routers (e.g., first 15) into:
     ```
     topologies/configs/quaggasrx-bgpsec/
     ```
   - The N+1 config file can be deleted.
   - For the router that will connect to the BGPSEC-IO injector (e.g., R14 to R0), update its BGP neighbor configuration.  
     For example, for AS 64614:

     ```bash
     neighbor 10.0.0.8 remote-as 64615
     neighbor 10.0.0.8 bgpsec both
     ```

4. **Integrate Docker Compose Config**

   - Copy the contents of `docker_compose_snippet.yml` into `topologies/docker-compose.yml`
   - Append it below services like `krill`, `krillc`, `tal_share`, etc.
   - Refer to the `topologies` folder for examples.

5. **Move Key Setup**

   Move the `key_setup` directory to the project root, at the same level as `scripts/` and `docker_images/`.

6. **Build and Start Containers**

   Go to the directory where `docker-compose.yml` is located and run:

   ```bash
   docker compose build
   docker compose up
   ```

#### Quagga (BGP)

Follow the exact same steps, but **skip** the `key_setup` and `./generate_asns.sh` step as it is not required for plain BGP.

---

### Phase 2: Running Experiments

1. **Navigate to the Experiment Directory**

   ```bash
   cd scripts/experiment-1-scalability/
   ```

2. **Generate Prefix List**

   Run the script to generate a prefix list:

   ```bash
   python3 generate_prefix_list.py
   ```

   - This creates a `prefixes.txt` file.
   - Move it to the `sending-prefix/` directory.

3. **Generate Injection Config**

   Based on the prefix list, generate the injection configuration.

   - For **BGPsec**:

     ```bash
     python3 generate_bgpsecio_conf.py
     ```

   - For **BGP**:

     ```bash
     python3 generate_exabgp_conf.py
     ```

   > 🛠️ Update the variables in the script files to match your topology.

   - Move the generated `.conf` file to the `sending-prefix/` directory.

4. **Run the Experiment**

   Make sure the script is executable, then run:

   ```bash
   ./automate_runs.sh bgpsec 10
   ```

   Replace `bgpsec` with `bgp` to run for plain BGP.  
   Replace `10` with your desired number of iterations.

---

### Output

The experiment will generate:
- RIB convergence time logs
- Docker resource usage statistics
- Traffic dumps

These can be processed to create various plots.

> 📈 Plotting scripts are **not included** in this repository.  
> If you would like access to them, feel free to contact me:  
> 📧 marijn.valks@os3.nl
