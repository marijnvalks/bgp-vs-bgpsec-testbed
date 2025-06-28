#This script creates the router config files for BGP and the router config part of the docker compose file. 
#You must manually place this snippet in the complete docker compose file

import os
import textwrap

def generate_topology(num_routers=3, base_asn=64600, output_dir="router-configs"):
    base_ip = 100  # start at 10.0.0.100

    os.makedirs(output_dir, exist_ok=True)
    os.makedirs("../../../scripts/experiment-1-scalability/experiments_results", exist_ok=True)

    docker_compose_entries = []

    for i in range(num_routers):
        asn = base_asn + i
        ip = f"10.0.0.{base_ip + i}"
        hostname = f"quagga_{i:02d}"

        # Create results dir per router
        result_dir = f"../../../scripts/experiment-1-scalability/experiments_results/{hostname}"
        os.makedirs(result_dir, exist_ok=True)

        neighbor_config = ""
        if i > 0:
            neighbor_ip = f"10.0.0.{base_ip + i - 1}"
            neighbor_asn = base_asn + i - 1
            neighbor_config += f"  neighbor {neighbor_ip} remote-as {neighbor_asn}\n"
        if i < num_routers - 1:
            neighbor_ip = f"10.0.0.{base_ip + i + 1}"
            neighbor_asn = base_asn + i + 1
            neighbor_config += f"  neighbor {neighbor_ip} remote-as {neighbor_asn}\n"

        bgp_config = f"""! -*- bgp -*-
!
hostname bgpd
password zebra

router bgp {asn}
  bgp router-id {ip}


{neighbor_config}log stdout
"""
        with open(f"{output_dir}/quagga_as{asn}.conf", "w") as f:
            f.write(bgp_config)

        entry = textwrap.dedent(f"""\
          {hostname}:
            container_name: {hostname}
            image: kathara/quagga
            privileged: true
            volumes:
              - ../../../scripts/experiment-1-scalability/measuring-prefix-arrival:/opt/scripts/
              - ../../configs/kathara-quagga/quagga_as{asn}.conf:/etc/bgpd.conf
              - ../../../scripts/experiment-1-scalability/experiments_results/{hostname}:/opt/experiment_output
              - ./entrypoint.sh:/entrypoint.sh
            entrypoint: ["/entrypoint.sh"]
            networks:
              bgp:
                ipv4_address: {ip}
""")
        docker_compose_entries.append(entry)

    with open(f"{output_dir}/docker_compose_snippet.yml", "w") as f:
        f.write("\n".join(docker_compose_entries))

    print(f"[✓] Generated {num_routers} BGP router configs in '{output_dir}/'")
    print(f"[✓] Docker Compose snippet written to '{output_dir}/docker_compose_snippet.yml'")
    print(f"[✓] Results will be written to 'experiments_results/{{hostname}}/'")

# Example usage
generate_topology(num_routers=15)
