module profile::profile;

use std::string::String;
use sui::{
    bag::{Self, Bag},
    bcs,
    display,
    ed25519,
    package,
    table::{Self, Table},
    vec_map::{Self, VecMap}
};

// === Structs ===

public struct Profile has key {
    id: UID,
    name: String,
    image_url: String,
    owner: address,
    metadata: VecMap<String, String>,
    plugins: Bag,
}

public struct Config has key {
    id: UID,
    public_key: vector<u8>,
    /// ctx.sender() -> Profile.id.to_address()
    profiles: Table<address, address>,
    /// Profile.id.to_address() -> nonce
    nonces: Table<address, u64>,
    plugins: Bag,
    version: u64,
}

public struct PluginKey<phantom T>() has copy, drop, store;

public struct ProfileAdmin has key, store {
    id: UID,
}

public struct MetadataMessage has copy, drop, store {
    profile: address,
    new_metadata: VecMap<String, String>,
    nonce: u64,
    version: u64,
}

public struct PROFILE() has drop;

// === Initializer ===

fun init(otw: PROFILE, ctx: &mut TxContext) {
    let sender = ctx.sender();

    let config = Config {
        id: object::new(ctx),
        public_key: vector[],
        profiles: table::new(ctx),
        plugins: bag::new(ctx),
        nonces: table::new(ctx),
        version: profile::profile_constants::package_version!(),
    };

    let admin = ProfileAdmin {
        id: object::new(ctx),
    };

    let publisher = package::claim(otw, ctx);

    let display = display::new<Profile>(&publisher, ctx);

    transfer::share_object(config);
    transfer::public_transfer(admin, sender);
    transfer::public_transfer(display, sender);
    transfer::public_transfer(publisher, sender);
}

// === Public Mutative Functions ===

public fun new(config: &mut Config, ctx: &mut TxContext): Profile {
    config.assert_package_version();

    let sender = ctx.sender();

    assert!(!config.profiles.contains(sender), profile::profile_errors::profile_already_created!());

    let profile = Profile {
        id: object::new(ctx),
        name: b"".to_string(),
        image_url: b"".to_string(),
        plugins: bag::new(ctx),
        owner: sender,
        metadata: vec_map::empty(),
    };

    config.profiles.add(sender, profile.id.to_address());

    profile
}

public fun share(profile: Profile) {
    transfer::share_object(profile);
}

public fun set_image_url(profile: &mut Profile, image_url: String, ctx: &mut TxContext) {
    profile.assert_is_owner(ctx);

    profile.image_url = image_url;
}

public fun set_name(profile: &mut Profile, name: String, ctx: &mut TxContext) {
    profile.assert_is_owner(ctx);

    profile.name = name;
}

public fun set_metadata(
    config: &mut Config,
    profile: &mut Profile,
    metadata: VecMap<String, String>,
    signature: vector<u8>,
    ctx: &mut TxContext,
) {
    config.assert_package_version();
    profile.assert_is_owner(ctx);

    let profile_address = profile.id.to_address();

    if (!config.nonces.contains(profile_address)) {
        config.nonces.add(profile_address, 0);
    };

    let nonce = &mut config.nonces[profile_address];

    let message = MetadataMessage {
        profile: profile_address,
        new_metadata: metadata,
        nonce: *nonce,
        version: config.version,
    };

    *nonce = *nonce + 1;

    assert!(
        ed25519::ed25519_verify(&signature, &config.public_key, &bcs::to_bytes(&message)),
        profile::profile_errors::invalid_metadata_signature!(),
    );

    profile.metadata = metadata;
}

// === Plugins API ===

public fun init_config_plugin<T: drop, PluginConfig: store>(
    config: &mut Config,
    _: T,
    plugin_config: PluginConfig,
    _ctx: &mut TxContext,
) {
    config.assert_package_version();

    config.plugins.add(PluginKey<T>(), plugin_config);
}

public fun config_plugin<T: drop, PluginConfig: store>(config: &Config): &PluginConfig {
    &config.plugins[PluginKey<T>()]
}

public fun config_plugin_mut<T: drop, PluginConfig: store>(
    config: &mut Config,
    _: T,
): &mut PluginConfig {
    config.assert_package_version();

    &mut config.plugins[PluginKey<T>()]
}

public fun init_profile_plugin<T: drop, ProfilePlugin: store>(
    profile: &mut Profile,
    _: T,
    profile_plugin: ProfilePlugin,
    _ctx: &mut TxContext,
) {
    profile.plugins.add(PluginKey<T>(), profile_plugin);
}

public fun profile_plugin<T: drop, ProfilePlugin: store>(profile: &Profile): &ProfilePlugin {
    &profile.plugins[PluginKey<T>()]
}

public fun profile_plugin_mut<T: drop, ProfilePlugin: store>(
    profile: &mut Profile,
    _: T,
): &mut ProfilePlugin {
    &mut profile.plugins[PluginKey<T>()]
}

public fun has_profile_plugin<T: drop>(profile: &Profile): bool {
    profile.plugins.contains(PluginKey<T>())
}

// === View Functions ===

public fun owner(profile: &Profile): address {
    profile.owner
}

public fun next_nonce(config: &Config, profile: address): u64 {
    config.assert_package_version();

    if (!config.nonces.contains(profile)) 0 else config.nonces[profile]
}

// === Admin Only Functions ===

public fun set_public_key(config: &mut Config, _: &ProfileAdmin, public_key: vector<u8>) {
    config.public_key = public_key;
}

public fun set_version(config: &mut Config, _: &ProfileAdmin, version: u64) {
    config.version = version;
}

// === Private Functions ===

fun assert_package_version(config: &Config) {
    assert!(
        config.version == profile::profile_constants::package_version!(),
        profile::profile_errors::outdated_package_version!(),
    );
}

fun assert_is_owner(profile: &Profile, ctx: &TxContext) {
    assert!(profile.owner == ctx.sender(), profile::profile_errors::not_owner!());
}
