# Change the below variables accordingly for the topology required.

def generate_bgp_config(prefix_file, output_file=None):
    with open(prefix_file, 'r') as f:
        prefixes = [line.strip() for line in f if line.strip()]

    config = """neighbor 10.0.0.109 {
  router-id 10.0.0.8;
  local-address 10.0.0.8;
  local-as 64610;
  peer-as 64609;
  hold-time 90;
  capability {
    asn4 enable;
  }

  family {
    ipv4 unicast;
  }

  static {
"""
    for prefix in prefixes:
        config += f"    route {prefix} next-hop 10.0.0.8;\n"

    config += "  }\n}\n"

    if output_file:
        with open(output_file, 'w') as f:
            f.write(config)
        print(f"BGP config written to {output_file}")
    else:
        print(config)

# Example usage
generate_bgp_config('prefixes.txt', 'exabgp.conf')
