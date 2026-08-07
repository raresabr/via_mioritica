/// Hive round-trips JSON maps as a `Map` with dynamic keys (not
/// `Map<String, dynamic>`), so every nested map read back from the cache
/// must be re-cast before being passed to a model's `fromJson`. Works
/// whether [v] came straight from `dart:convert`'s `json.decode` (already
/// `Map<String, dynamic>`) or from the Hive cache — including maps nested
/// inside lists nested inside other maps (e.g. a stage's `pois` list),
/// which is why models with nested collections must call this on every
/// level, not just the top one.
Map<String, dynamic> asStringKeyedMap(dynamic v) =>
    Map<String, dynamic>.from(v as Map);
