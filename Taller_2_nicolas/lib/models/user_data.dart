class UserData {
  final int id;
  final String nombre;
  final String correo;
  final String rol;
  final String avatar;
  final DateTime fechaRegistro;

  UserData({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.avatar,
    required this.fechaRegistro,
  });

  factory UserData.sample() {
    return UserData(
      id: 1024,
      nombre: 'Nicolás Lozano Salazar',
      correo: 'nicolas.lozano@universidad.edu.co',
      rol: 'Estudiante / Desarrollador Flutter',
      avatar: 'NL',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 120)),
    );
  }
}
