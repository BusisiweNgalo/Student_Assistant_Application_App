/**
*Student Number: 218009030, 220049798, 220033640, 222057332, 221002961.
*Student Name: TA RASEGO, LONWABO SIFUMBA, BN NGALO, TC LAAT, 221002961.
*Question: 
*/

class ApplicationModel {
  final String id;
  final String userId;
  final String studentNumber;
  final int yearOfStudy;
  final String module1Level;
  final String module1Name;
  final String? module2Level;
  final String? module2Name;
  final String? documentUrl;
  final String status; // pending, approved, rejected
  final DateTime createdAt;

  ApplicationModel({
    required this.id,
    required this.userId,
    required this.studentNumber,
    required this.yearOfStudy,
    required this.module1Level,
    required this.module1Name,
    this.module2Level,
    this.module2Name,
    this.documentUrl,
    required this.status,
    required this.createdAt,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    return ApplicationModel(
      id: map['id'],
      userId: map['user_id'],
      studentNumber: map['student_number'],
      yearOfStudy: map['year_of_study'],
      module1Level: map['module_1_level'],
      module1Name: map['module_1_name'],
      module2Level: map['module_2_level'],
      module2Name: map['module_2_name'],
      documentUrl: map['document_url'],
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'student_number': studentNumber,
      'year_of_study': yearOfStudy,
      'module_1_level': module1Level,
      'module_1_name': module1Name,
      'module_2_level': module2Level,
      'module_2_name': module2Name,
      'document_url': documentUrl,
      'status': status,
    };
  }

  ApplicationModel copyWith({
    String? module1Level,
    String? module1Name,
    String? module2Level,
    String? module2Name,
    String? documentUrl,
    String? status,
  }) {
    return ApplicationModel(
      id: id,
      userId: userId,
      studentNumber: studentNumber,
      yearOfStudy: yearOfStudy,
      module1Level: module1Level ?? this.module1Level,
      module1Name: module1Name ?? this.module1Name,
      module2Level: module2Level ?? this.module2Level,
      module2Name: module2Name ?? this.module2Name,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
