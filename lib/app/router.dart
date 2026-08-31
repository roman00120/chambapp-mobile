import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/features/admin/presentation/admin_feature.dart';
import 'package:chambapp_mobile/features/admin/presentation/admin_operations.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:chambapp_mobile/features/auth/presentation/auth_state.dart';
import 'package:chambapp_mobile/features/auth/presentation/login_screen.dart';
import 'package:chambapp_mobile/features/auth/presentation/register_screen.dart';
import 'package:chambapp_mobile/features/auth/presentation/splash_screen.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/catalog/presentation/professional_detail_screen.dart';
import 'package:chambapp_mobile/features/catalog/presentation/search_screen.dart';
import 'package:chambapp_mobile/features/catalog/presentation/service_detail_screen.dart';
import 'package:chambapp_mobile/features/catalog/presentation/service_request_screen.dart';
import 'package:chambapp_mobile/features/favorites/presentation/favorites_screen.dart';
import 'package:chambapp_mobile/features/home/presentation/client_home_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/immediate_job_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_detail_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/checkout_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/dispute_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/jobs_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/scheduled_job_screen.dart';
import 'package:chambapp_mobile/features/navigation/presentation/client_shell.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:chambapp_mobile/features/reports/presentation/security_center_screen.dart';
import 'package:chambapp_mobile/features/profile/presentation/profile_screen.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/availability_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/earnings_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/edit_professional_profile_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/identity_verification_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_home_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_jobs_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_profile_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_services_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_shell.dart';
import 'package:chambapp_mobile/features/professional/presentation/service_form_screen.dart';
import 'package:chambapp_mobile/features/reviews/presentation/review_form_screen.dart';
import 'package:chambapp_mobile/features/reviews/presentation/reviews_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(
    authControllerProvider.select(
      (state) => (
        state.status,
        state.user?.role,
        state.user?.activeMode,
        state.user?.canActAsClient ?? false,
        state.user?.canActAsProfessional ?? false,
      ),
    ),
  );
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, routeState) {
      final path = routeState.matchedLocation;
      final onAuthPage = path == '/login' || path == '/register';
      if (auth.$1 == AuthStatus.checking) {
        return path == '/splash' ? null : '/splash';
      }
      if (auth.$1 == AuthStatus.unauthenticated) {
        return onAuthPage ? null : '/login';
      }
      final role = auth.$2;
      final activeMode = auth.$3;
      final canClient = auth.$4;
      final canPro = auth.$5;
      final isProMode =
          activeMode == 'professional' ||
          (role == UserRole.professional && activeMode != 'client');
      final client = !isProMode && canClient;
      final admin = role == UserRole.admin && activeMode == null;
      if (path == '/splash' || onAuthPage) {
        return admin
            ? '/admin/home'
            : isProMode
            ? '/professional/home'
            : '/client/home';
      }
      if (role == UserRole.admin && path.startsWith('/admin')) return null;
      if (path.startsWith('/admin') && role != UserRole.admin) {
        return client ? '/client/home' : '/professional/home';
      }
      if (client && path == '/home') return '/client/home';
      if (!client && path == '/home') return '/professional/home';
      if (client && path == '/profile') return '/client/profile';
      if (!client && path == '/profile') return '/professional/profile';
      if (client && path.startsWith('/professional') && !canPro) {
        return '/client/home';
      }
      if (!client && path.startsWith('/client') && !canClient) {
        return '/professional/home';
      }
      if (client && path.endsWith('/quote')) return '/client/home';
      if (!client && path.endsWith('/checkout')) return '/professional/home';
      if (!client && path.endsWith('/dispute')) return '/professional/home';
      if (!client && path.endsWith('/review')) return '/professional/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/home', redirect: (_, _) => '/professional/home'),
      GoRoute(path: '/profile', redirect: (_, _) => '/professional/profile'),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdminShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/home',
                builder: (_, _) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                builder: (_, _) => const AdminUsersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/professionals',
                builder: (_, _) => const AdminProfessionalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/operations',
                builder: (_, _) => const AdminOperationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                builder: (_, _) => const AdminProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ClientShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/home',
                builder: (_, _) => const ClientHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/search',
                builder: (_, state) => SearchScreen(
                  initialQuery: state.uri.queryParameters['q'],
                  categorySlug: state.uri.queryParameters['category'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/jobs',
                builder: (_, _) => const JobsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/favorites',
                builder: (_, _) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ProfessionalShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/professional/home',
                builder: (_, _) => const ProfessionalHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/professional/jobs',
                builder: (_, _) => const ProfessionalJobsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/professional/services',
                builder: (_, _) => const ProfessionalServicesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/professional/earnings',
                builder: (_, _) => const EarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/professional/profile',
                builder: (_, _) => const ProfessionalProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/professional/availability',
        builder: (_, _) => const AvailabilityScreen(),
      ),
      GoRoute(
        path: '/professional/identity-verification',
        builder: (_, _) => const IdentityVerificationScreen(),
      ),
      GoRoute(
        path: '/professional/profile/edit',
        builder: (_, _) => const EditProfessionalProfileScreen(),
      ),
      GoRoute(
        path: '/professional/services/new',
        builder: (_, _) => const ServiceFormScreen(),
      ),
      GoRoute(
        path: '/professional/services/:id/edit',
        builder: (_, state) => ServiceFormScreen(
          service: state.extra is ProfessionalServiceModel
              ? state.extra! as ProfessionalServiceModel
              : null,
        ),
      ),
      GoRoute(
        path: '/services/:id',
        builder: (_, state) =>
            ServiceDetailScreen(serviceId: _id(state.pathParameters['id'])),
      ),
      GoRoute(
        path: '/services/:id/request',
        builder: (_, state) => ServiceRequestScreen(
          serviceId: _id(state.pathParameters['id']),
          service: state.extra is ServiceModel ? state.extra! as ServiceModel : null,
        ),
      ),
      GoRoute(
        path: '/professionals/:id',
        builder: (_, state) => ProfessionalDetailScreen(
          professionalId: _id(state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/request/immediate',
        builder: (_, state) => ImmediateJobScreen(
          initialCategoryId: _nullableId(state.uri.queryParameters['category']),
          serviceId: _nullableId(state.uri.queryParameters['service']),
        ),
      ),
      GoRoute(
        path: '/request/scheduled',
        builder: (_, state) {
          final serviceId = _nullableId(state.uri.queryParameters['service']);
          if (serviceId != null) {
            return ServiceRequestScreen(
              serviceId: serviceId,
              service: state.extra is ServiceModel ? state.extra! as ServiceModel : null,
            );
          }
          return ScheduledJobScreen(
            initialCategoryId: _nullableId(state.uri.queryParameters['category']),
          );
        },
      ),
      GoRoute(
        path: '/jobs/:id/searching',
        redirect: (_, state) => '/jobs/${state.pathParameters['id']}/checkout',
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (_, state) => JobDetailScreen(
          jobId: _id(state.pathParameters['id']),
          createdScheduled: state.uri.queryParameters['created'] == 'scheduled',
        ),
      ),
      GoRoute(
        path: '/jobs/:id/quote',
        redirect: (_, state) => '/jobs/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/jobs/:id/checkout',
        builder: (_, state) =>
            CheckoutScreen(jobId: _id(state.pathParameters['id'])),
      ),
      GoRoute(
        path: '/jobs/:id/dispute',
        builder: (_, state) =>
            DisputeScreen(jobId: _id(state.pathParameters['id'])),
      ),
      GoRoute(
        path: '/jobs/:id/review',
        builder: (_, state) => ReviewFormScreen(
          jobId: _id(state.pathParameters['id']),
          professionalId: _id(state.uri.queryParameters['professional']),
        ),
      ),
      GoRoute(
        path: '/professionals/:id/reviews',
        builder: (_, state) =>
            ReviewsScreen(professionalId: _id(state.pathParameters['id'])),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/security',
        builder: (_, _) => const SecurityCenterScreen(),
      ),
    ],
  );
});

int _id(String? value) => int.tryParse(value ?? '') ?? 0;
int? _nullableId(String? value) => int.tryParse(value ?? '');
