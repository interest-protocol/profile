// module profile::pool_rating;

// use profile::profile::{ProfileConfig, Profile};
// use sui::table::{Self, Table};

// // === Structs ===

// public enum Rating has copy, drop, store {
//     Rocket(u64),
//     Poop(u64),
// }

// public struct PoolRatingConfig has store {
//     ratings: Table<address, Rating>,
// }

// public struct ConfigKey() has copy, drop, store;

// public struct ProfileRating has store {
//     ratings: Table<address, Rating>,
// }

// // === Initialization ===

// public fun init_plugin(config: &mut ProfileConfig, ctx: &mut TxContext) {
//     let key = ConfigKey();
//     let config_mut = config.plugins_config_mut();

//     assert!(
//         !config_mut.contains(key),
//         profile::blast_profile_errors::plugin_already_initialized!(),
//     );

//     config_mut.add(
//         key,
//         PoolRatingConfig {
//             ratings: table::new(ctx),
//         },
//     );
// }
