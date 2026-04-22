import 'package:book/features/auth/data/apis/auth_apis.dart';
import 'package:book/features/auth/logic/auth_cubit.dart';
import 'package:book/features/bookDetails/data/apis/book_details_apis.dart';
import 'package:book/features/bookDetails/data/repos/book_details_repo.dart';
import 'package:book/features/bookDetails/logic/book_details_cubit.dart';
import 'package:book/features/dashboard/data/apis/dashboard_apis.dart';
import 'package:book/features/dashboard/data/repos/dashbaord_repo.dart';
import 'package:book/features/dashboard/logic/dashboard_cubit.dart';
import 'package:book/features/favorite/data/apis/favorite_apis.dart';
import 'package:book/features/favorite/data/repos/favorite_repo.dart';
import 'package:book/features/favorite/logic/favorite_cubit.dart';
import 'package:book/features/home/data/apis/home_apis.dart';
import 'package:book/features/home/data/repos/home_repo.dart';
import 'package:book/features/home/logic/home_cubit.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/data/repos/auth_repo.dart';
import '../localization/localization_cubit.dart';
import '../networking/dio_factory.dart';
import '../networking/socket_service.dart';
import '../services/location_service.dart';

final getIt = GetIt.instance;

Future<void> setupGetIt() async {
  // ✅ FIRST: Create and register Dio instance
  Dio dio = DioFactory.getDio();
  getIt.registerLazySingleton<Dio>(() => dio);

  // Register core services
  getIt.registerLazySingleton<LocaleCubit>(() => LocaleCubit());
  getIt.registerLazySingleton<LocationService>(() => LocationService());

  // Login & Register
  getIt.registerLazySingleton<AuthApis>(() => AuthApis(dio));
  getIt.registerLazySingleton<AuthRepo>(() => AuthRepo(getIt()));
  getIt.registerFactory<AuthCubit>(() => AuthCubit(getIt()));

  // Home
  getIt.registerLazySingleton<HomeApis>(() => HomeApis(dio));
  getIt.registerLazySingleton<HomeRepo>(() => HomeRepo(getIt()));
  getIt.registerFactory<HomeCubit>(() => HomeCubit(getIt()));

  // Dashboard - Now both DashboardApis and Dio are available
  getIt.registerLazySingleton<DashboardApis>(() => DashboardApis(dio));
  getIt.registerLazySingleton<DashboardRepo>(() => DashboardRepo(getIt()));
  getIt.registerFactory<DashboardCubit>(() => DashboardCubit(getIt()));

  // Book Details
  getIt.registerLazySingleton<BookDetailsApis>(() => BookDetailsApis(dio));
  getIt.registerLazySingleton<BookDetailsRepo>(() => BookDetailsRepo(getIt()));
  getIt.registerFactory<BookDetailsCubit>(() => BookDetailsCubit(getIt()));

  // favorite
  getIt.registerLazySingleton<FavoriteApis>(() => FavoriteApis(dio));
  getIt.registerLazySingleton<FavoriteRepo>(() => FavoriteRepo(getIt()));
  getIt.registerFactory<FavoriteCubit>(() => FavoriteCubit(getIt()));
}