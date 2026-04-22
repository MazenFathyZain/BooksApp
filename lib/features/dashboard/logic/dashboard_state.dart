part of 'dashboard_cubit.dart';

@immutable
sealed class DashboardState {}

final class DashboardInitial extends DashboardState {}
final class DashboardLoading extends DashboardState {}
final class DashboardSuccess extends DashboardState {
  final AddBookResponse response;
  DashboardSuccess(this.response);
}
final class DashboardFailed extends DashboardState {
  final String error;
  DashboardFailed(this.error);
}
