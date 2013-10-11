#! /usr/bin/env bash

## default mode for installation
## hard_mode = hard_kernel_setup.sh  
## soft_mode = soft_kernel_setup.sh
## package_mode = package_setup.sh
ovs_setup_mode=${ovs_setup_mode:=soft_kernel_setup.sh}
$(find / -wholename $(pwd)/$ovs_setup_mode)
