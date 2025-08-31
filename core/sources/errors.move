#[allow(unused_const)]
module profile::profile_errors;

#[test_only]
const EProfileAlreadyCreated: u64 = 1;

#[test_only]
const EInvalidMetadataSignature: u64 = 2;

#[test_only]
const EProfileDoesNotExist: u64 = 3;

#[test_only]
const ENotOwner: u64 = 4;

#[test_only]
const EOutdatedPackageVersion: u64 = 5;

public(package) macro fun profile_already_created(): u64 {
    1
}

public(package) macro fun invalid_metadata_signature(): u64 {
    2
}

public(package) macro fun profile_does_not_exist(): u64 {
    3
}

public(package) macro fun not_owner(): u64 {
    4
}

public(package) macro fun outdated_package_version(): u64 {
    5
}
