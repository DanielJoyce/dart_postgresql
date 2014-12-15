part of postgresql.protocol;

// http://www.postgresql.org/docs/9.2/static/protocol-message-formats.html

abstract class ProtocolMessage {
  int get messageCode;
  List<int> encode();
    
  // Note msgBodyLength excludes the 5 byte header. Is 0 for some message types.
  static ProtocolMessage decode(int msgType, int msgBodyLength, ByteReader byteReader) {
    try {
      assert(msgBodyLength <= byteReader.bytesAvailable);
    } catch (ex) {
      print('foo');
    }
    var decoder = _messageDecoders[msgType];
    if (decoder == null) throw new Exception('Unknown message type: $msgType'); //TODO exception type, and atoi on messageType.
    var msg = decoder(msgType, msgBodyLength, byteReader);
    return msg;
  }

  // Some message codes are ambigous, as reused for both front and backend.
  // Note msgBodyLength excludes the 5 byte header. Is 0 for some message types.
  static ProtocolMessage decodeBackend(int msgType, int msgBodyLength, ByteReader byteReader) {
    assert(msgBodyLength <= byteReader.bytesAvailable);
    var decoder = _messageDecodersBackend[msgType];
    if (decoder == null) throw new Exception('Unknown message type: $msgType'); //TODO exception type, and atoi on messageType.
    var msg = decoder(msgType, msgBodyLength, byteReader);
    return msg;
  }
  
}

// One day dart will have ascii constants :(
const int _C = 67;
const int _c = 99;  
const int _D = 68;
const int _d = 100;
//const int _E = 69;
const int _f = 102;
const int _G = 71;
const int _H = 72;
//const int _I = 73;
const int _K = 75;
const int _N = 78;
const int _p = 112;
const int _Q = 81;
const int _R = 82;
//const int _S = 83;
//const int _T = 84;
const int _X = 88;
const int _Z = 90;

const int _1 = 49;
const int _2 = 50;
const int _3 = 51;
const int _A = 65;
const int _B = 66;
const int _n = 110;
const int _P = 80;
const int _s = 115;


// TODO remove backend only messages
const Map<int,Function> _messageDecoders = const {  
  _C : CommandComplete.decode,
  _c : CopyDone.decode,
  _D : DataRow.decode,
  _d : CopyData.decode,
  _E : ErrorResponse.decode,
  _f : CopyFail.decode,
  _G : CopyInResponse.decode,
  _H : CopyOutResponse.decode,
  _I : EmptyQueryResponse.decode,
  _K : BackendKeyData.decode,
  _Q : Query.decode,
  _N : NoticeResponse.decode,
  _p : PasswordMessage.decode,
  _R : AuthenticationRequest.decode,
  _S : ParameterStatus.decode,
  _T : RowDescription.decode,
  _X : Terminate.decode,
  _Z : ReadyForQuery.decode,
  
  _B : Bind.decode,
  _2 : BindComplete.decode,
//Ambigious frontend backend
//  _C : Close.decode,
  _3 : CloseComplete.decode,
//  _D : Describe.decode,
//  _E : Execute.decode,
//  _H : Flush.decode,
  _n : NoData.decode,
  _A : NotificationResponse.decode,
  _t : ParameterDescription.decode,
  _P : Parse.decode,
  _1 : ParseComplete.decode,
  _s : PortalSuspended.decode,
//  _S : Sync.decode
};


// TODO remove frontend only messages
const Map<int,Function> _messageDecodersBackend = const { 
//    _C : CommandComplete.decode,
    _c : CopyDone.decode,
//    _D : DataRow.decode,
    _d : CopyData.decode,
//    _E : ErrorResponse.decode,
    _f : CopyFail.decode,
    _G : CopyInResponse.decode,
//    _H : CopyOutResponse.decode,
    _I : EmptyQueryResponse.decode,
    _K : BackendKeyData.decode,
    _Q : Query.decode,
    _N : NoticeResponse.decode,
    _p : PasswordMessage.decode,
    _R : AuthenticationRequest.decode,
//    _S : ParameterStatus.decode,
    _T : RowDescription.decode,
    _X : Terminate.decode,
    _Z : ReadyForQuery.decode,
    
    _B : Bind.decode,
    _2 : BindComplete.decode,
    _C : Close.decode,
    _3 : CloseComplete.decode,
    _D : Describe.decode,
    _E : Execute.decode,
    _H : Flush.decode,
    _n : NoData.decode,
    _A : NotificationResponse.decode,
    _t : ParameterDescription.decode,
    _P : Parse.decode,
    _1 : ParseComplete.decode,
    _s : PortalSuspended.decode,
    _S : Sync.decode
};

class Startup implements ProtocolMessage {
  
  Startup(this.user, this.database, [this.parameters = const {}]) {
    if (user == null || database == null) throw new ArgumentError();
  }
  
  // Startup and ssl request are the only messages without a messageCode.
  final int messageCode = 0; 
  final int protocolVersion = 196608;
  final String user;
  final String database;
  final Map<String,String> parameters;
  
  List<int> encode() {
    var mb = new MessageBuilder(messageCode)
      ..addInt32(protocolVersion)
      ..addUtf8('user')
      ..addUtf8(user)
      ..addUtf8('database')
      ..addUtf8(database)
      ..addUtf8('client_encoding')
      ..addUtf8('UTF8');    
    parameters.forEach((k, v) {
      mb.addUtf8(k);
      mb.addUtf8(v);
    });
    mb.addByte(0);
    
    return mb.build();
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
    'protocolVersion': protocolVersion,
    'user': user,
    'database': database
  });
}

class SslRequest implements ProtocolMessage {
  // Startup and ssl request are the only messages without a messageCode.
  final int messageCode = 0;
  
  List<int> encode() => <int> [0, 0, 0, 8, 4, 210, 22, 47];
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
  });
}

class Terminate implements ProtocolMessage {
  
  final int messageCode = _X;
  
  List<int> encode() => new MessageBuilder(messageCode).build();
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _X);
    if (bodyLength != 0) throw new Exception(); //FIXME
    return new Terminate();
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
  });
}

//const int authTypeOk = 0;
//const int authTypeMd5 = 5;

//const int authOk = 0;
//const int authKerebosV5 = 2;
//const int authScm = 6;
//const int authGss = 7;
//const int authClearText = 3;


class AuthenticationRequest implements ProtocolMessage {
  
  AuthenticationRequest.ok() : authType = 0, salt = null;
  
  AuthenticationRequest.md5(this.salt)
      : authType = 5 {
    if (salt == null || salt.length != 4) throw new Exception(); //FIXME
  }
  
  final int messageCode = _R;
  final int authType;
  final List<int> salt;
  
  List<int> encode() {
    var mb = new MessageBuilder(messageCode);
    mb.addInt32(authType);
    if (authType == 5) mb.addBytes(salt);
    return mb.build();
  }
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _R);
    int authType = r.readInt32();
    if (authType == 0) {
      return new AuthenticationRequest.ok();
    
    } else if (authType == 5) {
      var salt = r.readBytes(4);
      return new AuthenticationRequest.md5(salt);
    } else {
      throw new Exception('Invalid authType: $authType');
    }
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
    'authType': {0: "ok", 5: "md5"}[authType],
    'salt': salt
  });
}

class PasswordMessage implements ProtocolMessage {
  
  PasswordMessage(this.password);
  
  final int messageCode = _p;
  
  final String password;
  
  List<int> encode() {
    var mb = new MessageBuilder(messageCode);
    mb.addUtf8(password);
    return mb.build();    
  }
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _p);
    return new PasswordMessage(r.readString());
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'password': password
  });
}

class BackendKeyData implements ProtocolMessage {
  
  BackendKeyData(this.backendPid, this.secretKey) {
    if (backendPid == null || secretKey == null) throw new ArgumentError();
  }
  
  final int messageCode = _K;
  final int backendPid;
  final int secretKey;
  
  List<int> encode() {
    var mb = new MessageBuilder(messageCode)
      ..addInt32(backendPid)
      ..addInt32(secretKey);
    return mb.build();
  }
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _K);
    if (bodyLength != 8) throw new Exception(); //FIXME
    int pid = r.readInt32();
    int key = r.readInt32();
    return new BackendKeyData(pid, key);
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
    'backendPid': backendPid,
    'secretKey': secretKey
  });
}

class ParameterStatus implements ProtocolMessage {
  
  ParameterStatus(this.name, this.value);
  
  final int messageCode = _S;
  final String name;
  final String value;
  
  List<int> encode() {
    var mb = new MessageBuilder(messageCode)
      ..addUtf8(name)
      ..addUtf8(value);
    return mb.build();
  }
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _S);
    var name = r.readString();
    var value = r.readString();
    return new ParameterStatus(name, value);
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
    'name': name,
    'value': value});
}


class Query implements ProtocolMessage {
  
  Query(this.query) {
    if (query == null) throw new ArgumentError();
  }
  
  final int messageCode = _Q;
  final String query;
  
  List<int> encode()
    => (new MessageBuilder(messageCode)..addUtf8(query)).build(); //FIXME why do I need extra parens here. Analyzer bug?
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _Q);
    var query = r.readString();
    return new Query(query);
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
    'query': query});
}


class Field {
  
  Field({
    this.name,
    this.fieldId: 0,
    this.tableColNo: 0,
    this.fieldType,
    this.dataSize: -1,
    this.typeModifier: 0,
    this.formatCode: 0}) {
    if (name == null || fieldType == null) throw new ArgumentError();
  }
  
  final String name;
  final int fieldId;
  final int tableColNo;
  final int fieldType;
  final int dataSize;
  final int typeModifier;
  final int formatCode;
  
  bool get isBinary => formatCode == 1;
  
  String toString() => JSON.encode(toJson());
  
  Map toJson() => {
    'name': name,
    'fieldId': fieldId,
    'tableColNo': tableColNo,
    'fieldType': fieldType,
    'dataSize': dataSize,
    'typeModifier': typeModifier,
    'formatCode': formatCode
  };  
}

class RowDescription implements ProtocolMessage {
  
  RowDescription(this._fields) {
    if (_fields == null) throw new ArgumentError();
  }
  
  final int messageCode = _T;
  
  final List<Field> _fields;
  List<Field> get fields => new UnmodifiableListView(_fields);
  
  List<int> encode() {
    var mb = new MessageBuilder(messageCode) 
      ..addInt16(fields.length);

    for (var f in fields) {
      mb..addUtf8(f.name)
        ..addInt32(f.fieldId)
        ..addInt16(f.tableColNo)
        ..addInt32(f.fieldType)
        ..addInt16(f.dataSize)
        ..addInt32(f.typeModifier)
        ..addInt16(f.formatCode);
    }
    
    return mb.build();
  }
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _T);
    int maxlen = bodyLength;
    int count = r.readInt16();
    var fields = new List(count);
    for (int i = 0; i < count; i++) {
      var field = new Field(
          name: r.readString(),
          fieldId: r.readInt32(),
          tableColNo: r.readInt16(),
          fieldType: r.readInt32(),
          dataSize: r.readInt16(),
          typeModifier: r.readInt32(),
          formatCode: r.readInt16());
      fields[i] = field;
    }
    return new RowDescription(fields);
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
    'fields': fields});
}


class DataRow implements ProtocolMessage {
  
  DataRow.fromBytes(this._values) {
    if (_values == null) throw new ArgumentError();
  }

  DataRow.fromStrings(List<String> strings)
    : _values = strings.map(UTF8.encode).toList(growable: false);
  
  final int messageCode = _D;
  
  final List<List<int>> _values;
  List<List<int>> get values => _values;
  
  
  List<int> encode() {
    var mb = new MessageBuilder(messageCode)
      ..addInt16(_values.length);
    
    for (var bytes in _values) {
      mb..addInt32(bytes.length)
        ..addBytes(bytes);
    }
    
    return mb.build();
  }
  
  //FIXME this currently copies data. Make a zero-copy version.
  // ... caller will need to use zero copy version carefully.
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _D);
    int count = r.readInt16();
    var values = new List(count);
    for (int i = 0; i < count; i++) {
      int len = r.readInt32();
      var bytes = r.readBytes(len);
      values[i] = bytes;
    }
    return new DataRow.fromBytes(values);
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
    'values': _values.map(UTF8.decode).toList() //TODO not all DataRows are text, some are binary.
  });
}

class CopyInResponse implements ProtocolMessage {
  
  final int messageCode = _G;
  
  CopyInResponse(this.format, this.columns, this.columnFormats);
  
  // TODO provide better names like isBinary.
  final int format;
  final int columns;
  final List<int> columnFormats;
  
  List<int> encode() {
    var mb = new MessageBuilder(messageCode)
      ..addByte(format)
      ..addInt16(columns);
    
    columnFormats.forEach((i) => mb.addInt16(i));
    
    return mb.build();
  }
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _G);
    int format = r.readByte();
    int columns = r.readInt16();
    List<int> columnFormats = new List<int>(columns);
    for (int i = 0; i < columns; i++) {
      columnFormats[i] = r.readInt16();
    }
    return new CopyInResponse(format, columns, columnFormats);
  }
}

//FIXME share code with CopyInResponse
class CopyOutResponse implements ProtocolMessage {
  
  final int messageCode = _H;
  
  CopyOutResponse(this.format, this.columns, this.columnFormats);
  
  // TODO provide better names like isBinary.
  final int format;
  final int columns;
  final List<int> columnFormats;
  
  List<int> encode() {
    var mb = new MessageBuilder(messageCode)
      ..addByte(format)
      ..addInt16(columns);
    
    columnFormats.forEach((i) => mb.addInt16(i));
    
    return mb.build();
  }
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _H);
    int format = r.readByte();
    int columns = r.readInt16();
    List<int> columnFormats = new List<int>(columns);
    for (int i = 0; i < columns; i++) {
      columnFormats[i] = r.readInt16();
    }
    return new CopyOutResponse(format, columns, columnFormats);
  }
}

class CopyData implements ProtocolMessage {
  CopyData(this.data);
  
  final int messageCode = _d;
  final List<int> data;
  
  List<int> get header {
    var bytes = new Uint8List(5);
    
    bytes[0] = _d;
    
    int i = data.length + 4;
    bytes[1] = (i >> 24) & 0x000000FF;
    bytes[2] = (i >> 16) & 0x000000FF;
    bytes[3] = (i >> 8) & 0x000000FF;
    bytes[4] = i & 0x000000FF;
    
    return bytes;
  }
  
  // Note this copies the data so that it can all fit in a single buffer.
  // This is not actually used by ProtocolClient.send() for efficiency reasons.
  List<int> encode() {
    var bytes = new Uint8List(data.length + 4);
    bytes.setRange(0, 5, header);
    bytes.setRange(5, bytes.length, data);
    return bytes;
  }
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _d);
    // TODO experiment with zero copy streaming. i.e. copy: false.
    return new CopyData(r.readBytes(bodyLength, copy: true));
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode)
  });
}

class CopyDone implements ProtocolMessage {
  final int messageCode = _c;
  
  List<int> encode() => [_c, 0, 0, 0, 4];
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _c);
    assert(bodyLength == 0);
    return new CopyDone();
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode)
  });
}

class CopyFail implements ProtocolMessage {
  CopyFail(this.message);
  final int messageCode = _f;
  final String message;
  
  List<int> encode() => (new MessageBuilder(messageCode)
    ..addUtf8(message)).build();
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _f);
    return new CopyFail(r.readString());
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
    'message': message
  });
}

// TODO expose rows and oid getter
class CommandComplete implements ProtocolMessage {
  
  CommandComplete(this.tag);
  
  CommandComplete.insert(int oid, int rows) : this('INSERT $oid $rows');
  CommandComplete.delete(int rows) : this('DELETE $rows');
  CommandComplete.update(int rows) : this('UPDATE $rows');
  CommandComplete.select(int rows) : this('SELECT $rows');
  CommandComplete.move(int rows) : this('MOVE $rows');
  CommandComplete.fetch(int rows) : this('FETCH $rows');
  CommandComplete.copy(int rows) : this('COPY $rows');
  
  final int messageCode = _C;
  final String tag;
  
  int get rowsAffected => int.parse(tag.split(' ').last, onError: (_) => null);
  
  List<int> encode() => (new MessageBuilder(messageCode)..addUtf8(tag)).build(); //FIXME why extra parens needed?
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _C);
    var tag = r.readString();
    return new CommandComplete(tag);
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
    'tag': tag
  });
}


//FIXME use an enum when implemented
//class TransactionState {
//  const TransactionState(this._name);
//  final String _name;
//  static const TransactionState none = const TransactionState('TransactionStatus.none'); // idle
//  static const TransactionState transaction = const TransactionState('TransactionStatus.transaction'); // in transaction
//  static const TransactionState failed = const TransactionState('TransactionStatus.failed'); // failed transaction
//}

class ReadyForQuery implements ProtocolMessage {
  
  ReadyForQuery.fromState(this.transactionState);
  
  ReadyForQuery(int statusCode)
      : transactionState = _txStatusR[statusCode] {
    if (transactionState == null) throw new Exception(); //FIXME
  }
  
  final int messageCode = _Z;
  final TransactionState transactionState;
  
  static const Map _txStatus = const {
    TransactionState.none: _I,
    TransactionState.begun: _T,
    TransactionState.error: _E
  };

  static const Map _txStatusR = const {
    _I: TransactionState.none,
    _T: TransactionState.begun,
    _E: TransactionState.error,
  };
  
  List<int> encode() {
    var mb = new MessageBuilder(messageCode)
      ..addByte(_txStatus[transactionState]);
    return mb.build();
  }
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _Z);
    if (bodyLength != 1) throw new Exception(); //FIXME
    int statusCode = r.readByte();
    return new ReadyForQuery(statusCode);
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
    'transactionStatus': _txStatus[transactionState]
  });
}

abstract class BaseResponse implements ProtocolMessage {
  
  BaseResponse(Map<String,String> fields)
      : fields = new UnmodifiableMapView<String,String>(fields) {
    if (fields == null) throw new ArgumentError();
    assert(fields.keys.every((k) => k.length == 1));
  }
  
  String get severity => fields['S'];
  String get code => fields['C'];
  String get message => fields['M'];
  String get detail => fields['D'];
  String get hint => fields['H'];
  String get position => fields['P'];
  String get internalPosition => fields['p'];
  String get internalQuery => fields['q'];
  String get where => fields['W'];
  String get schema => fields['s'];
  String get table => fields['t'];
  String get column => fields['c'];
  String get dataType => fields['d'];
  String get constraint => fields['n'];
  String get file => fields['F'];
  String get line => fields['L'];
  String get routine => fields['R'];
  
  final Map<String, String> fields;
  
  List<int> encode() {
    final mb = new MessageBuilder(messageCode);
    fields.forEach((k, v) => mb..addByte(k.codeUnitAt(0))..addUtf8(v));
    mb.addByte(0); // Terminator
    return mb.build();
  }
  
  static BaseResponse decode(int msgType, int bodyLength, ByteReader r) {
    int maxlen = bodyLength;
    
    final fields = <String,String>{};
    int key;
    String value;
    while ((key = r.readByte()) != 0) {
      value = r.readString();
      var k = new String.fromCharCode(key);
      fields[k] = value;
    }
    
    return msgType == _E
        ? new ErrorResponse(fields)
        : new NoticeResponse(fields);
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode),
    'fields': fields
  });
}

class ErrorResponse extends BaseResponse implements ProtocolMessage {
  ErrorResponse(Map<String,String> fields) : super(fields);
  final int messageCode = _E;
  
  static ErrorResponse decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _E);
    return BaseResponse.decode(msgType, bodyLength, r);
  }
}

class NoticeResponse extends BaseResponse implements ProtocolMessage {
  NoticeResponse(Map<String,String> fields) : super(fields);
  final int messageCode = _N;
  
  static NoticeResponse decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _N);
    return BaseResponse.decode(msgType, bodyLength, r);
  }
}

class EmptyQueryResponse implements ProtocolMessage {  
  
  final int messageCode = _I;
  
  List<int> encode() => new MessageBuilder(messageCode).build();
  
  static ProtocolMessage decode(int msgType, int bodyLength, ByteReader r) {
    assert(msgType == _I);
    if (bodyLength != 0) throw new Exception(); //TODO
    return new EmptyQueryResponse();
  }
  
  String toString() => JSON.encode({
    'msg': runtimeType.toString(),
    'code': new String.fromCharCode(messageCode)
  });
}
