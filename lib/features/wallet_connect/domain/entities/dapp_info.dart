import 'package:equatable/equatable.dart';

/// dApp information entity
class DappInfo extends Equatable {
  final String name;
  final String url;
  final String? iconUrl;
  final String? description;

  const DappInfo({
    required this.name,
    required this.url,
    this.iconUrl,
    this.description,
  });

  @override
  List<Object?> get props => [name, url, iconUrl, description];
}
