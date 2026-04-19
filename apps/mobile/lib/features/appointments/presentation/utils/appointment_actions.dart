class AppointmentActionAvailability {
  AppointmentActionAvailability({required this.status});

  final String status;

  bool get isTerminal => status == 'CANCELLED' || status == 'DECLINED' || status == 'COMPLETED' || status == 'NO_SHOW';

  bool get canReschedule => !isTerminal;
  bool get canCancel => !isTerminal;

  bool get canAcceptDecline => status == 'REQUESTED';
  bool get canCompleteOrNoShow => status == 'ACCEPTED' || status == 'RESCHEDULED';

  bool get canRate => status == 'COMPLETED' || status == 'NO_SHOW';
}
