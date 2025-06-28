#This script creates the router config files for BGPsec and the router config part of the docker compose file. 
#You must manually place this snippet under the other docker container entries, like routinator, bgpsecio, krill, etc.

import os
import textwrap

def parse_ski_list(ski_list_path):
    ski_map = {}
    with open(ski_list_path, "r") as f:
        for line in f:
            if "-SKI:" in line:
                asn, ski = line.strip().split(":")
                asn_number = int(asn.split("-")[0])
                ski_map[asn_number] = ski.strip()
    return ski_map

def read_asn_list(asn_list_path):
    with open(asn_list_path, "r") as f:
        return [int(line.strip()) for line in f if line.strip().isdigit()]

def generate_topology(ski_list_path="./key_setup/testbed_keys/ski-list.txt",
                      asn_list_path="key_setup/topology_asns",
                      output_dir="router-configs"):

    base_ip = 100  # start at 10.0.0.100

    ski_map = parse_ski_list(ski_list_path)
    asn_list = read_asn_list(asn_list_path)

    os.makedirs(output_dir, exist_ok=True)
    os.makedirs("experiments_results", exist_ok=True)

    docker_compose_entries = []

    for i, asn in enumerate(asn_list):
        ip = f"10.0.0.{base_ip + i}"
        hostname = f"quaggasrx_{i:02d}"

        # Create results dir per router
        result_dir = f"experiments_results/{hostname}"
        os.makedirs(result_dir, exist_ok=True)

        config_file_path = f"../../configs/quaggasrx-bgpsec/quagga_as{asn}.conf"
        ski = ski_map[asn]

        neighbor_config = ""
        if i > 0:
            neighbor_ip = f"10.0.0.{base_ip + i - 1}"
            neighbor_asn = asn_list[i - 1]
            neighbor_config += f"  neighbor {neighbor_ip} remote-as {neighbor_asn}\n  neighbor {neighbor_ip} bgpsec both\n"
        if i < len(asn_list) - 1:
            neighbor_ip = f"10.0.0.{base_ip + i + 1}"
            neighbor_asn = asn_list[i + 1]
            neighbor_config += f"  neighbor {neighbor_ip} remote-as {neighbor_asn}\n  neighbor {neighbor_ip} bgpsec both\n"

        bgp_config = f"""! -*- bgp -*-
!
hostname bgpd
password zebra

router bgp {asn}
  bgp router-id {ip}

  srx display
  srx set-proxy-id {ip}
  srx set-server 10.0.0.15 17900
  srx connect
  no srx extcommunity

  srx evaluation bgpsec distributed
  srx set-bgpsec-value undefined

  srx policy bgpsec local-preference valid   add      20
  srx policy bgpsec local-preference invalid subtract 20
  no srx policy bgpsec ignore undefined

  srx bgpsec ski 0 1 {ski}
  srx bgpsec active 0


{neighbor_config}log stdout
"""
        with open(f"{output_dir}/quagga_as{asn}.conf", "w") as f:
            f.write(bgp_config)

        entry = textwrap.dedent(f"""\
          {hostname}:
            container_name: {hostname}
            image: quaggasrx
            build:
              context: ../../../docker_images/quaggasrx-bgpsec
              network: host
            volumes:
              - ../../../key_setup/testbed_keys:/var/lib/bgpsec-keys
              - {config_file_path}:/etc/quagga.conf
              - rsync_ta:/etc/routinator/krill-tal
              - ../../configs/srxcryptoapi.conf:/usr/local/etc/srxcryptoapi.conf
              - ../../../scripts/experiment-1-scalability/measuring-prefix-arrival:/opt/scripts/
              - ../../../experiments_results/{hostname}:/opt/experiment_output
            networks:
              bgp:
                ipv4_address: {ip}
            depends_on:
              - srx_server
        """)
        docker_compose_entries.append(entry)

    with open(f"{output_dir}/docker_compose_snippet.yml", "w") as f:
        f.write("\n".join(docker_compose_entries))

    print(f"[✓] Generated {len(asn_list)} router configs in '{output_dir}/'")
    print(f"[✓] Docker Compose snippet written to '{output_dir}/docker_compose_snippet.yml'")
    print(f"[✓] Results will be written to 'experiments_results/{{hostname}}/'")

# Example usage
generate_topology()
