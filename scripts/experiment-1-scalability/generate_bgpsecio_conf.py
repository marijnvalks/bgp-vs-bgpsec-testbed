#Create BGPSEC-IO config file, based on the current topology change the variables for IP and AS number. 
#Always create N + 1 amount of routers, so you can use the key material from N + 1 router as key material for BGPSECIO.
#So when creating a 15 AS topology, you can use the ASn number and crypto material from R15

def generate_bgpsecio_conf(prefix_file="prefixes.txt", output_file="bgpsecio.conf"):
    with open(prefix_file) as f:
        prefixes = [f"\"{line.strip()}\"" for line in f if line.strip()]

    updates = ",\n        ".join(prefixes)
    conf = f"""ski_file    = "/var/lib/bgpsec-keys/ski-list.txt";
ski_key_loc = "/var/lib/bgpsec-keys";
signature_generation = "CAPI";
only_extended_length = true;
mode = "BGP";
max = 0;

session = (
  {{
    asn        = 64615;
    bgp_ident  = "10.0.0.8";
    hold_timer = 90;
    peer_asn   = 64614;
    peer_ip    = "10.0.0.114";
    peer_port  = 179;
    disconnect = 0;
    ext_msg_cap = true;
    ext_msg_liberal = true;
    bgpsec_v4_snd = true;
    bgpsec_v4_rcv = true;
    update = (
        {updates}
    );
    algo_id = 1;
    null_signature_mode = "DROP";
    printOnSend = false;
  }}
);

update = ();
"""
    with open(output_file, "w") as f:
        f.write(conf)
    print(f"[OK] Generated {output_file} with {len(prefixes)} prefixes")

# Example
generate_bgpsecio_conf()
