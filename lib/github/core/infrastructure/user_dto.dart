import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:repo_viewer/github/core/domain/user.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
class UserDTO with _$UserDTO {
  const UserDTO._();
  const factory UserDTO({
    @JsonKey(name: 'login') required String name,
    @JsonKey(name: 'avatar_url') required String avatarUrl,
  }) = _UserDTO;

  factory UserDTO.fromJson(Map<String, dynamic> json) =>
      _$UserDTOFromJson(json);

  // this conversion from domain and to domain is going to happen at the
  // boundary of the infrastructure layer. Because repositories take in entities
  // and output data transfer objects, and also take in data transfer objects
  // from the services and output entities.
  
  factory UserDTO.fromDomain(User _) {
    return UserDTO(
      name: _.name,
      avatarUrl: _.avatarUrl,
    );
  }

  User toDomain(){
    return User(
      name: name,
      avatarUrl: avatarUrl,
    );
  }
}

class Test {

}
