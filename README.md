
# BGP vs BGPsec Virtual Testbed

A virtual testbed used during my master’s thesis research on router overhead and convergence time in BGPsec compared to regular BGP.

This repository contains various scripts and configuration files used to set up a Quagga (BGP) and QuaggaSRx (BGPsec) testbed for topologies with N routers. ExaBGP (for BGP) and BGPSEC-IO (for BGPsec) are used to inject N prefixes into the network.

For all router containers, Docker stats, RIB convergence times, and network traffic have been recorded.

My full thesis can be found here: [link]

The QuaggaSRx setup is based on earlier work by SIDN: https://github.com/SIDN/bgpsec-testbed/tree/main
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
