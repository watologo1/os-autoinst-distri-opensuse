# SUSE's openQA tests
#
# Copyright 2025 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: tuned
# Summary: TODO
# Maintainer: trenn@suse.com


use Mojo::Base 'opensusebasetest';

use testapi;
use serial_terminal 'select_serial_terminal';



sub run {
    record_info('HALLO', 'Wurst ist Lecker!');
    select_serial_terminal;

    my $output = script_output('cat /etc/os-release');

    record_info('os-release', $output);
}


42;
