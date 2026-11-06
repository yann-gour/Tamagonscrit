class Announcement {
  final String id;
  final String title;
  final String text;
  final DateTime startDate;
  final DateTime endDate;

  const Announcement({
    required this.id,
    required this.title,
    required this.text,
    required this.startDate,
    required this.endDate,
  });

  bool isActiveAt(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return (dateOnly.isAfter(startOnly) || dateOnly.isAtSameMomentAs(startOnly)) &&
        (dateOnly.isBefore(endOnly) || dateOnly.isAtSameMomentAs(endOnly));
  }
}

final List<Announcement> allAnnouncements = [
  Announcement(
    id: 'elections_soce_2026',
    title: 'Elections SOCE',
    text: 'Pour les sociétaire, pensez à voter pour le CA de la SOCE cette semaine !',
    startDate: DateTime(2026, 11, 9),
    endDate: DateTime(2026, 11, 14),
  ),
  Announcement(
    id: 'fignos_birse',
    title: "Nuit des Fignos à Birse et Bapt's à KIN",
    text: "Joyeuse Nuit des Fignos aux birsois et joyeux Bapt's aux KINois !",
    startDate: DateTime(2026, 11, 28),
    endDate: DateTime(2026, 11, 29),
  ),
  Announcement(
    id: 'fignos_chalons',
    title: "Nuit des Fignos à Chalon's et Ste Cécile à Boquette",
    text: "Joyeuse Nuit des Fignos aux chalonais et joyeuse Ste Cécile aux boquettois !",
    startDate: DateTime(2026, 12, 5),
    endDate: DateTime(2026, 12, 6),
  ),
  Announcement(
    id: 'fignos_bordels',
    title: "Nuit des Fignos à Bordel's et Nuit des Gadz à Siber's",
    text: "Joyeuse Nuit des Fignos aux bordel'sois et joyeuse Nuit des Gadz aux siber'sois !",
    startDate: DateTime(2026, 12, 12),
    endDate: DateTime(2026, 12, 13),
  ),
  Announcement(
    id: 'gg_p3',
    title: "Grand Gala à P3",
    text: "C'est le GG à P3 ! J'espère que vous avez pris vos places...",
    startDate: DateTime(2026, 3, 13),
    endDate: DateTime(2026, 3, 14),
  ),
  Announcement(
    id: '508_kin',
    title: "508 à KIN",
    text: "Joyeux 508 aux KINois !",
    startDate: DateTime(2026, 3, 20),
    endDate: DateTime(2026, 3, 21),
  ),
  Announcement(
    id: '100j_kin',
    title: "Nuit des 100 Jours à KIN",
    text: "Joyeuse Nuit des 100 Jours aux KINois !",
    startDate: DateTime(2026, 5, 22),
    endDate: DateTime(2026, 5, 23),
  ),
  Announcement(
    id: 'gg_cluns',
    title: "Grand Gala à Clun's",
    text: "Joyeux GG aux clun'sois !",
    startDate: DateTime(2026, 5, 29),
    endDate: DateTime(2026, 5, 30),
  ),
];
