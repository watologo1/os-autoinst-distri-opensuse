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
   my $self = shift;

    $self->comment("Starte Test für Kernel-Bootparameter nach Reboot.");

    # 1. Paket installieren
    $self->comment("Installiere Paket 'tuned'...");
    my ($exit_code, $output) = $self->zypper_install("tuned");
    if ($exit_code != 0) {
        $self->fail("Installation von 'tuned' fehlgeschlagen. Ausgabe: $output");
        return;
    }
    $self->pass("Paket 'tuned' erfolgreich installiert.");

    # 2. Kernel-Bootparameter setzen
    systemctl("enable tuned");
    systemctl("start tuned");

   
    # 3. Reboot durchführen
    $self->comment("Führe Reboot durch...");
    $self->reboot();
    $self->wait_for_console(); # Warten, bis die Konsole wieder erreichbar ist
    $self->login();           # Optional: Falls eine Anmeldung erforderlich ist

    # 4. Überprüfen, ob der Kernel-Bootparameter aktiv ist
    $self->comment("Überprüfe, ob die Kernel-Bootparameter aktiv sind...");

    my @expected_kernel_parameters = (
        "hardened_usercopy=on",
        "init_on_free=1",
        "init_on_alloc=1",
	"page_poison=on",
	"page_table_check=on"
    ); # <-- HIER EINE LISTE VON ERWARTETEN PARAMETERN ANPASSEN

    my ($exit_code_cmdline, $current_cmdline_output) = $self->run_command("cat /proc/cmdline");

    if ($exit_code_cmdline != 0) {
        $self->fail("Konnte /proc/cmdline nicht lesen. Exit-Code: $exit_code_cmdline");
        return;
    }

    foreach my $param (@expected_kernel_parameters) {
        if ($current_cmdline_output =~ m/\b\Q$param\E\b/) {
            $self->pass("Kernel-Bootparameter '$param' ist aktiv.");
        } else {
            $self->fail("Kernel-Bootparameter '$param' ist NICHT aktiv. Gefunden in /proc/cmdline: $current_cmdline_output");
        }
    }
   $self->comment("Test für Kernel-Bootparameter nach Reboot abgeschlossen.");
}


42;
