# Introduction 
This repository represents the minimal content required to create a custom Mariner Derivative.  It is part of a tutorial.

## Extract toolkit
Download the `toolkit.tar.gz` file to disk, then:
```bash
cd ~/demo
tar -xzf ~/toolkit.tar.gz
```

## Build VHDX
```bash
cd toolkit
sudo make image CONFIG_FILE=../imageconfigs/demo_vhdx.json
```

## Output Files
The sample package `hello_world-demo-*.x86_64.rpm` can be found in `~/demo/out/RPMS/x86_64/` along with all the other packages which were needed for image generation.

`minimal_demo.vhdx` can be found in ``~/demo/out/images/`.