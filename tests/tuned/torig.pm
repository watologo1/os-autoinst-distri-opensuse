# SUSE's openQA tests
#
# Copyright 2025 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: tuned
# Summary: TODO
# Maintainer: trenn@suse.com


use Mojo::Base 'opensusebasetest';

use testapi;
use serial_terminal qw(select_serial_terminal reboot);



sub run {
    record_info('HALLO', 'Wurst ist Lecker!');
    select_serial_terminal;

    my $output = script_output('cat /etc/os-release');

    record_info('os-release', $output);

    # simply wait one minute to see a uptime
    sleep 65;

    record_info('uptime', script_output('uptime'));
    reboot;
    record_info('uptime', script_output('uptime'));
}

42;
