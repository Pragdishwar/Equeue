import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/user/branch_detail_screen.dart';
import '../screens/user/branches_screen.dart';
import '../screens/user/home_screen.dart';
import '../screens/user/notifications_screen.dart';
import '../screens/user/queue_tracking_screen.dart';
import '../screens/user/token_history_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/queue_management_screen.dart';
import '../screens/admin/manage_branches_screen.dart';
import '../screens/admin/manage_services_screen.dart';
import '../screens/admin/reports_screen.dart';

// Keys for navigation state preservation
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = authService.currentUser;
      final isLoggedIn = user != null;
      
      final isGoingToSplash = state.matchedLocation == '/';
      final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      // 1. Unauthenticated users
      if (!isLoggedIn) {
        if (!isGoingToSplash && !isGoingToAuth && !isGoingToOnboarding) {
          return '/login';
        }
        return null;
      }

      // 2. Authenticated users going to auth pages
      if (isGoingToSplash || isGoingToAuth || isGoingToOnboarding) {
        return '/home';
      }

      // 3. Admin Route Guards
      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      if (isAdminRoute) {
        final profile = ref.read(currentProfileProvider).valueOrNull;
        if (profile != null && !profile.isAdmin) {
          return '/home'; // Kick normal user out of admin panel
        }
      }

      return null;
    },
    routes: [
      // Standalone Public Screens
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // USER SHELL ROUTE (Bottom Navigation)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return UserScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'queue/:tokenId',
                    parentNavigatorKey: _rootNavigatorKey, // Overlay on top of nav bar
                    builder: (context, state) {
                      final tokenId = state.pathParameters['tokenId']!;
                      return QueueTrackingScreen(tokenId: tokenId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 1: Branches tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/branches',
                builder: (context, state) => const BranchesScreen(),
                routes: [
                  GoRoute(
                    path: ':branchId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final branchId = state.pathParameters['branchId']!;
                      return BranchDetailScreen(branchId: branchId);
                    },
                  ),
                  GoRoute(
                    path: 'history',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const TokenHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Notifications tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          // Branch 3: Profile tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ADMIN SHELL ROUTE (Admin Bottom Navigation)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Admin Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (context, state) => const AdminDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'reports',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ReportsScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Admin Branch 1: Live Queue console
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/queue',
                builder: (context, state) => const QueueManagementScreen(),
              ),
            ],
          ),
          // Admin Branch 2: Branches CRUD
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/branches',
                builder: (context, state) => const ManageBranchesScreen(),
              ),
            ],
          ),
          // Admin Branch 3: Services CRUD
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/services',
                builder: (context, state) => const ManageServicesScreen(),
              ),
            ],
          ),
          // Admin Branch 4: Profile tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                builder: (context, state) => const ProfileScreen(), // Reuse user profile
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM USER NAVBAR LAYOUT
// ─────────────────────────────────────────────────────────────────────────────

class UserScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const UserScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadCountProvider);
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(index),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_rounded),
              activeIcon: Icon(Icons.storefront_rounded, color: AppColors.primary),
              label: 'Branches',
            ),
            BottomNavigationBarItem(
              icon: Badge.count(
                count: unreadCount,
                isLabelVisible: unreadCount > 0,
                child: const Icon(Icons.notifications_rounded),
              ),
              activeIcon: Badge.count(
                count: unreadCount,
                isLabelVisible: unreadCount > 0,
                child: const Icon(Icons.notifications_rounded, color: AppColors.primary),
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM ADMIN NAVBAR LAYOUT
// ─────────────────────────────────────────────────────────────────────────────

class AdminScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(index),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.secondary, // Admin uses purple/indigo accent
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.queue_play_next_rounded),
              label: 'Console',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_rounded),
              label: 'Branches',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_suggest_rounded),
              label: 'Services',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
