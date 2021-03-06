# Trustlines Smart Contract Platform

Smart Contracts, Unittests and Infrastructure for Trustlines App.

## Installation

The Smart Contracts can be installed separately from the other components of the Trustlines App.

### Prerequisites

 * Python 3.6
 * [pip](https://pip.pypa.io/en/stable/)

### Setup

 * pip install -r requirements.txt

### Usage

_Note: all command should be executed from the root directory_

 * compilation: `populus compile`
 * unittest:    `pytest`
 * deploy:      `python deploy/deploy_testrpc.py`

For deployment a running _ethereumjs-testrpc_ (`testrpc`) with default values is mandatory.
