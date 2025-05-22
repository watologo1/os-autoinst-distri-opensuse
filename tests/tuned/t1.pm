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


sub install_package_and_service {
    my ($self, $pkg_name, $service_name) = @_;

    # Paket installieren
    zypper_call("in $pkg_name");

    # Service aktivieren und starten (falls benötigt)
    systemctl("enable $service_name");
    systemctl("start $service_name");
}

sub do_reboot {
    # Reboot durchführen
    type_string("reboot\n");
    assert_shutdow();
    reset_consoles;
    boot_to_login_screen(timeout => 300);
}

sub run {

    my ($self) = @_;

    select_serial_terminal;

    # 1. Paket installieren & Reboot
    $self->install_package_and_service(
        "tuned",  # Name des Pakets
        "tuned"   # Name des systemd-Service
	);
    do_reboot;
}


42;
