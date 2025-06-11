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
use utils qw(zypper_call systemctl);


sub install_package_and_service {
    my ($self, $pkg_name, $service_name) = @_;

    zypper_call("in $pkg_name");

    systemctl("enable $service_name");
    systemctl("start $service_name");
}

sub tuned_set_profile {
    my $tuned_profile = shift;

    record_info("Activating Profile $tuned_profile");
    assert_script_run "tuned-adm profile $tuned_profile";
    validate_script_output 'tuned-adm active', sub { m/${tuned_profile}/ };
    my $verify_output = script_output("tuned-adm verify 2>&1",
                                      proceed_on_failure => 1);
    my $verify_exit = $? >> 8;

    if ($verify_exit != 0) {
      record_info("tuned-adm verify FAILED for $tuned_profile",
                  $verify_output,
                  result => 'fail');
    }
    record_info("$tuned_profile activated");
}

sub test_kernel_params {

    # Test whether kernel parameters are set and survive reboot
    # using hardening profile

    my @missing_params;
    my $procfile = '/proc/cmdline';
    my @params = (
                  'hardened_usercopy=on',
                  'init_on_free=1',
                  'init_on_alloc=1',
                  'page_poison=on',
                  'page_table_check=on'
                 );

    record_info("Starting kernel parameter test on hardening profile");
    tuned_set_profile("hardening");
    reboot();
    select_serial_terminal;

    validate_script_output 'tuned-adm active', sub { m/hardening/ };
    my $proc_cmdline = script_output("cat \'$procfile\'");
    record_info("Kernel Params", "Current params: $proc_cmdline");

    foreach my $param (@params) {
        if ($proc_cmdline !~ /\Q$param\E/) {
            push @missing_params, $param;
        }
    }

    if (@missing_params) {
        my $missing = join("\n  - ", @missing_params);
        my $expected = join("\n  - ", @params);
        record_info("Missing Kernel Parameters After Reboot",
                    "$procfile: $proc_cmdline\nExpected kernel params: $expected\nMissing kernel params: $missing",
                    result => 'fail');
    }
}

sub run {

    my ($self) = @_;
    my $tuned_log = '/var/log/tuned/tuned.log';

    # list of profiles we check
    my @tuned_profiles = (
                          'balanced',
                          'powersave',
                          'throughput-performance',
                          'network-latency',
                          'virtual-guest'
                         );

    select_serial_terminal;
    $self->install_package_and_service(
        "tuned",
        "tuned"
    );

    my $available_profiles = script_output('tuned-adm list');
    record_info("TUNED Profiles", "Available profiles:\n$available_profiles");
    record_info("TUNED Profiles getting verfied",
                "Verifying profiles:\n@tuned_profiles");

    foreach my $profile (@tuned_profiles) {
        if ($available_profiles !~ /^\-\s$profile$/m) {
            record_info("Profile $profile not available", "", result => 'fail');
            next
        }
        tuned_set_profile($profile);
    }


    # Check for errors in tuned.log
    my $log_check = script_output(
       'grep -i "ERROR" /var/log/tuned/tuned.log || echo "NO_ERRORS_FOUND"',
       proceed_on_failure => 1
    );

    if ($log_check !~ /NO_ERRORS_FOUND/) {
      record_info("Errors in log", $log_check);
      record_info("Last 1000 lines of log",
                  script_output('tail -n 1000 /var/log/tuned/tuned.log'));
    }

    test_kernel_params();

}


42;
