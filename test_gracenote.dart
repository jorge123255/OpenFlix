import 'lib/services/gracenote_epg_service.dart';

void main() async {
  print('🧪 Testing Gracenote EPG Service...\n');

  try {
    final epgService = GracenoteEPGService();

    print('📡 Fetching TV listings from Gracenote...');
    final channels = await epgService.getTVListings(
      affiliateId: 'orbebb',
      hours: 3,
    );

    print('✅ Success! Got ${channels.length} channels\n');

    if (channels.isNotEmpty) {
      print('📺 Sample channels:');
      print('─' * 50);
      for (var ch in channels.take(10)) {
        print('${ch.channelNo.padRight(6)} ${ch.callSign}');
        if (ch.events.isNotEmpty) {
          print('       Now: ${ch.events.first.program.title}');
        }
        print('');
      }
    }

    print('✅ Test completed successfully!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
