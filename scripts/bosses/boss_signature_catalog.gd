class_name BossSignatureCatalog
extends Resource

## Catalogo autorevole delle Signature Evil (PS-006): associa ogni profilo del
## cast alla propria mossa Boss. Vive accanto al `BossEncounter` e non conosce
## ne' il roster giocabile ne' le `AbilityDefinition`.

@export var signatures: Array[BossSignatureDefinition] = []


func get_valid_signatures() -> Array[BossSignatureDefinition]:
	var valid: Array[BossSignatureDefinition] = []
	for signature in signatures:
		if signature != null and signature.is_valid():
			valid.append(signature)
	return valid


func resolve_for_friend(friend_id: StringName) -> BossSignatureDefinition:
	if friend_id.is_empty():
		return null
	for signature in get_valid_signatures():
		if signature.friend_id == friend_id:
			return signature
	return null


## Candidati che Evil Lollo puo' copiare: mai Cosplay Casuale, mai una
## Signature non valida.
func get_copy_candidates() -> Array[BossSignatureDefinition]:
	return BossSignatureRegistry.get_copy_candidates(get_valid_signatures())


func is_valid() -> bool:
	var valid := get_valid_signatures()
	if valid.size() != signatures.size() or valid.is_empty():
		return false
	var seen_ids: Dictionary = {}
	var seen_friends: Dictionary = {}
	for signature in valid:
		if seen_ids.has(signature.id) or seen_friends.has(signature.friend_id):
			return false
		seen_ids[signature.id] = true
		seen_friends[signature.friend_id] = true
	return true
