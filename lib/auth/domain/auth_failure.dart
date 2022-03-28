//this will be a freezed union.
import 'package:freezed_annotation/freezed_annotation.dart';

//STEP 2: 
//add ptf for freezed part statement
part 'auth_failure.freezed.dart';

//STEP 1:
//generate this with funion
@freezed
class AuthFailure with _$AuthFailure {
  const AuthFailure._();
  //individual case classes for this union:
  const factory AuthFailure.server([String? message]) = _Server;
  const factory AuthFailure.storage() = _Storage;
}

//STEP 3: run the following: flutter pub run build_runner watch --delete-conflicting-outputs.
