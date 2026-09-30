enum BookingStatus {
  confirmed('Confirmado'),
  cancelled('Cancelado'),
  pending('Pendente');

  const BookingStatus(this.label);

  final String label;

  static BookingStatus fromDb(String value) {
    switch (value.toLowerCase()) {
      case 'confirmado':
        return BookingStatus.confirmed;
      case 'cancelado':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }
}
