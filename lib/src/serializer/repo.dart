part of jaguar_serializer.serializer;

/// Default key added to a serialize Object to add his [Type]
const String defaultTypeInfoKey = "@t";

/// Repository that contains [Serializer] for a [Type].
///
/// Example:
///
///     SerializerRepo repository = new SerializerRepo();
///     respository.add(new UserSerializer());
///
///     User user = new User();
///
///     // serialize
///     Map<String, dynamic> map = repository.serialize(user);
///     List<Map<String,dynamic>> list = repository.serialize([ user ] );
///
///     // deserialize
///     user = repository.deserialize(map, type: User);
///     List<User> users = repository.deserialize(list, type: User);
class SerializerRepo {
  final Map<Type, Serializer> _mapperType = {};
  final Map<String, Serializer> _mapperString = {};

  SerializerRepo({String typeKey: defaultTypeInfoKey}) : _typeKey = typeKey;

  /// Key added to a map when serializing an Object
  final String _typeKey;

  String getTypeKey() => _typeKey;

  /// Return a [Serializer] for a Type
  ///
  /// Throw an [Exception] if no [Serializer]
  Serializer getByType(Type type) {
    if (_mapperType.containsKey(type)) {
      return _mapperType[type];
    }
    throw new Exception("No Serializer found for $type");
  }

  /// Return a [Serializer] for a String representing his [Type]
  ///
  /// Throw an [Exception] if no [Serializer]
  Serializer getByTypeKey(String name) {
    final serializer = _mapperString[name];
    if (serializer == null) {
      throw new Exception("No Serializer found for type key $name");
    }
    return serializer;
  }

  /// Add a [Serializer] to the repository.
  ///
  /// If a [Serializer] using the same type is already in the repository, it
  /// won't be override.
  void add(Serializer serializer) {
    if (!_mapperType.containsKey(serializer.modelType())) {
      _mapperType[serializer.modelType()] = serializer;
    }
    //TODO what if different serializers with same name are added?
    if (!_mapperString.containsKey(serializer.modelString)) {
      _mapperString[serializer.modelString()] = serializer;
    }
  }

  /// Convert the given [Object] to a serialized [Object], [Map] or [List]
  ///
  /// If [withType] is set to true, the serialized [Object] will contain a key
  /// ([typeKey]) with the type of the object as a value.
  ///
  /// The [typeKey] can be override using the [typeKey] option.
  dynamic serialize(dynamic object, {bool withType: false, String typeKey}) {
    typeKey ??= _typeKey;
    if (object is Iterable) {
      return encode(object
          .map((obj) => _to(obj,
              type: obj.runtimeType, withType: withType, typeKey: typeKey))
          .toList());
    } else if (object is Map) {
      Map map = {};
      for (var key in object.keys) {
        map[key] = _to(object[key],
            type: object[key].runtimeType,
            withType: withType,
            typeKey: typeKey);
      }
      return encode(map);
    }
    return encode(_to(object,
        type: object.runtimeType, withType: withType, typeKey: typeKey));
  }

  /// Deserialize the given [Object] ([Map] or [List]).
  ///
  /// If the [type] option is specified, it will be used to get the correct [Serializer].
  ///
  /// If not, it will look at if the object contain the [typeKey] and will use it
  /// to get the correct [Serializer].
  ///
  /// The [typeKey] can be override using the [typeKey] option.
  dynamic deserialize(dynamic object, {Type type, String typeKey}) {
    typeKey ??= _typeKey;
    final decoded = object is String ? decode(object) : object;

    if (decoded is Iterable) {
      return decoded
          .map((obj) => _from(obj, type: type, typeKey: typeKey))
          .toList();
    }
    return _from(decoded, type: type, typeKey: typeKey);
  }

  ///@nodoc
  dynamic encode(dynamic object) => object;

  ///@nodoc
  dynamic decode(dynamic object) => object;

  dynamic _to(dynamic object,
      {Type type, bool withType: false, String typeKey}) {
    typeKey ??= _typeKey;
    if (object is String || object is num) {
      return object;
    }
    final Serializer serializer = getByType(type);

    if (serializer == null) {
      throw new Exception("Cannot find serializer for type $type");
    }

    return serializer.serialize(object, withType: withType, typeKey: typeKey);
  }

  dynamic _from(dynamic decoded, {Type type, String typeKey}) {
    Serializer serializer;

    try {
      serializer = getByType(type);
    } catch (e) {
      final String typeInfo = _objectToType(decoded, typeKey);
      if (typeInfo is String) {
        serializer = getByTypeKey(typeInfo);
      }
    }
    if (serializer == null) {
      throw new Exception("Cannot find serializer for type $type");
    }

    return serializer.deserialize(decoded);
  }

  String _objectToType(object, String infoKey) {
    String typeKey;
    if (object is Map) {
      typeKey = object[infoKey];
    } else if (object is List<Map> &&
        object.length != 0 &&
        object.first is Map) {
      typeKey = object.first[infoKey];
    }
    return typeKey;
  }
}
