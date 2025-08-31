#[allow(unused_const)]
module profile::profile_constants;

#[test_only]
const PACKAGE_VERSION: u64 = 1;

public(package) macro fun package_version(): u64 {
    1
}
