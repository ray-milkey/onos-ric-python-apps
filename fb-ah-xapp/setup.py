#!/usr/bin/env python3
# Copyright 2004-present Facebook. All Rights Reserved.

from setuptools import find_packages, setup


setup(
    name="airhop_pci",
    packages=find_packages(),
    python_requires=">=3.7",
    install_requires=["onos-ric-sdk-python>=0.1.7"],
)
