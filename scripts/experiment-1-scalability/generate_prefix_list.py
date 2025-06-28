#Change the number to specfic number of prefixes wanted. This prefix list is needed as an input for both generate_bgpsecio_conf.py and generate_exabgp_conf.py
#The prefix list is also needed by the monitor_prefix_arrival.sh bash script, so place a copy of the prefixes.txt file in the "measuring-prefix-arrival" directory.

import ipaddress

def generate_prefixes(n, base="10.100.0.0", prefix_len=24, outfile="prefixes.txt"):
    base_ip = ipaddress.IPv4Address(base)
    step = 2**(32 - prefix_len)

    with open(outfile, "w") as f:
        for i in range(n):
            prefix_ip = base_ip + (i * step)
            f.write(f"{prefix_ip}/{prefix_len}\n")

    print(f"[OK] Generated {n} prefixes of /{prefix_len} starting at {base} into {outfile}")

# Example usage
generate_prefixes(10000, base="10.100.0.0", prefix_len=24)
