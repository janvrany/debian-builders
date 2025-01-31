#!/usr/bin/env python3
"""
Simple script to compute L2 cache size for .qcow2 image of given size.
See https://blogs.igalia.com/berto/2015/12/17/improving-disk-io-performance-in-qemu-2-5-with-the-qcow2-l2-cache/

"""

def GB_to_B(x):
    return x * 1024 * 1024 * 1024

def KB_to_B(x):
    return x * 1024

def l2_cache_size(image_size_in_bytes, cluster_size_in_bytes):
    return int(image_size_in_bytes / (cluster_size_in_bytes / 8))

def refcount_cache_size(image_size_in_bytes, cluster_size_in_bytes):
    return int(l2_cache_size(image_size_in_bytes, cluster_size_in_bytes) / 4)

def cache_size(image_size_in_bytes, cluster_size_in_bytes):
    return l2_cache_size(image_size_in_bytes, cluster_size_in_bytes) + refcount_cache_size(image_size_in_bytes, cluster_size_in_bytes)

if __name__ == '__main__':
    import argparse
    import sys
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image-size", metavar="IMAGE_SIZE_IN_GB", type=int,
                        dest='image_size', required=True,
                        help="virtual size of .qcow2 image in GB")
    parser.add_argument("--cluster-size", metavar="CLUSTER_SIZE_IN_KB", type=int,
                        dest='cluster_size', default="64",
                        help="cluster size of qcow2 image in k")

    options = parser.parse_args()

    print("<max_size unit=\"bytes\">%s</max_size>" % cache_size(GB_to_B(options.image_size), KB_to_B(options.cluster_size)))

