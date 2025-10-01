import 'dart:math';
import 'package:uuid/uuid.dart';
import '../constants.dart';
import '../models/group.dart';
import '../models/person.dart';
import '../models/message.dart';

class MockRepository {
  final _uuid = const Uuid();
  final _rng = Random(42);

  List<Group> loadGroups() {
    return const [
      Group(id: 'friends', name: 'Friends', type: GroupType.friends),
      Group(id: 'business', name: 'Business', type: GroupType.business),
      Group(id: 'gamers', name: 'Gamers', type: GroupType.custom),
    ];
  }

  List<Person> loadPeople() {
    final names = [
      'Alex', 'Sam', 'Jordan', 'Taylor', 'Casey', 'Riley',
      'Quinn', 'Avery', 'Morgan', 'Parker', 'Jamie', 'Drew'
    ];

    final avatars = List.generate(names.length, (i) => 'https://i.pravatar.cc/150?img=${i + 1}');
    final groupIds = ['friends', 'business', 'gamers'];

    return List.generate(names.length, (i) {
      final angle = _rng.nextDouble() * pi * 2;
      // Distances in meters; spread across buckets
      final bucket = _rng.nextInt(4);
      double dist;
      if (bucket == 0) {
        // neighborhood: 50m..4900m
        dist = ProximityConstants.minMockDistanceM + 
               _rng.nextDouble() * (ProximityConstants.neighborhoodRangeM - ProximityConstants.minMockDistanceM - 100);
      } else if (bucket == 1) {
        // city: 5km..28km
        dist = ProximityConstants.neighborhoodRangeM + 
               _rng.nextDouble() * (ProximityConstants.cityRangeM - ProximityConstants.neighborhoodRangeM - 2000);
      } else if (bucket == 2) {
        // country: 30km..200km
        dist = ProximityConstants.cityRangeM + 
               _rng.nextDouble() * (ProximityConstants.countryRangeM - ProximityConstants.cityRangeM);
      } else {
        // extras: >200km..2000km
        dist = ProximityConstants.countryRangeM + 
               _rng.nextDouble() * (ProximityConstants.maxDistanceM - ProximityConstants.countryRangeM);
      }
      final groups = <String>{ groupIds[_rng.nextInt(groupIds.length)] };
      return Person(
        id: _uuid.v4(),
        name: names[i],
        avatarUrl: avatars[i],
        groupIds: groups,
        distanceMeters: dist,
        angleRadians: angle,
        isOnline: _rng.nextBool(),
      );
    });
  }

  List<ChatMessage> initialMessagesFor(String personId) {
    return [
      ChatMessage(
        id: _uuid.v4(),
        fromId: personId,
        toId: 'me',
        text: 'Hey! You nearby?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      ChatMessage(
        id: _uuid.v4(),
        fromId: 'me',
        toId: personId,
        text: 'Yep, around the corner.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];
  }
}


