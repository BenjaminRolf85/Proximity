import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../widgets/radar_view.dart';
import '../widgets/person_list_item.dart';
import '../widgets/filter_bar.dart';
import '../state/people_provider.dart';
import '../state/broadcast_provider.dart';
import '../state/auth_state.dart';
import '../state/websocket_provider.dart';
import '../api/websocket_service.dart';
import '../api/api_providers.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import '../services/notification_service.dart';
import '../version.dart';
import 'chat_screen.dart';
import 'group_management_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _motion;
  String? _cityName = 'Test Location'; // Test value

  @override
  void initState() {
    super.initState();
    // Movement simulation disabled per requirements
    print('🔥 HOME SCREEN INIT CALLED!');
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    print('🌍 Loading location in HomeScreen...');
    try {
      final position = await LocationService().getCurrentPositionSafe();
      print('📍 Position result: $position');
      
      if (position != null && mounted) {
        print('✅ Got valid position: ${position.latitude}, ${position.longitude}');
        
        // First show coordinates immediately
        setState(() {
          _cityName = '${position.latitude.toStringAsFixed(2)}°, ${position.longitude.toStringAsFixed(2)}°';
        });
        
        // Then try to get city name
        print('🔍 Attempting geocoding...');
        try {
          final city = await GeocodingService().getShortLocation(position);
          print('🏙️ Geocoding result: $city');
          if (city != null && mounted) {
            setState(() {
              _cityName = city;
            });
          }
        } catch (e) {
          print('❌ Geocoding failed: $e');
          // Keep coordinates as fallback
        }
      } else {
        print('❌ Position is null');
      }
    } catch (e) {
      print('❌ Location error: $e');
    }
  }

  @override
  void dispose() {
    _motion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(filteredPeopleProvider);
    final wsStatus = ref.watch(websocketConnectionProvider);
    
    // Initialize WebSocket message handler
    ref.watch(websocketMessageHandlerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Radius Social'),
                const SizedBox(width: 6),
                Text(
                  AppVersion.shortVersion,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                _WebSocketStatusIndicator(status: wsStatus),
              ],
            ),
            if (_cityName != null)
              Text(
                _cityName!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Manage groups',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupManagementScreen())),
            icon: const Icon(Icons.group_outlined),
          ),
          IconButton(
            tooltip: 'Broadcast',
            onPressed: _showBroadcastSheet,
            icon: const Icon(Icons.campaign_outlined),
          ),
          IconButton(
            tooltip: 'Profil',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(authStateProvider.notifier).logout();
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: RadarView(
                        people: people,
                        maxRangeMeters: ProximityConstants.maxRadarRangeM,
                        onTapPerson: (p) {
                          NearbyNotificationService.sendPing(context, p.name);
                          ref.read(peopleProvider.notifier).ping(p.id);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const FilterBar(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Nearby', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text('${people.length} people'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverList.separated(
              itemBuilder: (context, index) {
                final p = people[index];
                return PersonListItem(
                  person: p,
                  onPing: () => NearbyNotificationService.sendPing(context, p.name),
                  onOpenChat: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(person: p)));
                  },
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: people.length,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBroadcastSheet,
        icon: const Icon(Icons.campaign),
        label: const Text('Broadcast'),
      ),
    );
  }

  void _showBroadcastSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _BroadcastSheet(onSend: (text) async {
        final authState = ref.read(authStateProvider);
        
        if (authState.isAuthenticated) {
          // Send via backend
          try {
            final messagesApi = ref.read(messagesApiProvider);
            await messagesApi.sendBroadcast(text: text);
            Navigator.pop(context);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Broadcast sent within ${ProximityConstants.broadcastRangeM.toInt()}m')),
              );
            }
          } catch (e) {
            Navigator.pop(context);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error sending broadcast: $e')),
              );
            }
          }
        } else {
          // Mock mode
          ref.read(broadcastProvider.notifier).broadcast(text);
          Navigator.pop(context);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Broadcast sent within ${ProximityConstants.broadcastRangeM.toInt()}m')),
            );
          }
        }
      }),
    );
  }
}

class _BroadcastSheet extends StatefulWidget {
  const _BroadcastSheet({required this.onSend});
  final void Function(String text) onSend;

  @override
  State<_BroadcastSheet> createState() => _BroadcastSheetState();
}

class _BroadcastSheetState extends State<_BroadcastSheet> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom, top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Broadcast to ${ProximityConstants.broadcastRangeM.toInt()}m', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Type your broadcast message…',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) widget.onSend(text);
                },
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebSocketStatusIndicator extends StatelessWidget {
  const _WebSocketStatusIndicator({required this.status});
  
  final WebSocketStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      WebSocketStatus.connected => Colors.green,
      WebSocketStatus.connecting => Colors.orange,
      WebSocketStatus.disconnected => Colors.grey,
      WebSocketStatus.error => Colors.red,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}


