// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_vlc_player/flutter_vlc_player.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// class AlertDetailScreen extends StatefulWidget {
//   final Map<String, dynamic> alert;

//   const AlertDetailScreen({super.key, required this.alert});

//   @override
//   _AlertDetailScreenState createState() => _AlertDetailScreenState();
// }

// class _AlertDetailScreenState extends State<AlertDetailScreen> {
//   late VlcPlayerController _vlcController;

//   @override
//   void initState() {
//     super.initState();

//     // Lấy RTSP từ .env
//     String rtspUrl = dotenv.env['RTSP_URL'] ?? '';

//     _vlcController = VlcPlayerController.network(
//       rtspUrl,
//       hwAcc: HwAcc.full,
//       autoPlay: true,
//       options: VlcPlayerOptions(),
//     );

//     _vlcController.addListener(() {
//       if (!mounted) return;
//       final playingState = _vlcController.value.isPlaying;
//       debugPrint("VLC Playing: $playingState");
//     });
//   }

//   @override
//   void dispose() {
//     _vlcController.dispose();
//     super.dispose();
//   }

//   String getFormattedTimestamp() {
//     String timestamp = widget.alert['timestamp'] ?? 'N/A';
//     try {
//       DateTime dateTime = DateFormat(
//         "MMMM dd, yyyy 'at' hh:mm:ssa",
//       ).parse(timestamp);
//       return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
//     } catch (e) {
//       return 'Invalid timestamp';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Alert Details')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Camera ID: ${widget.alert['cameraId'] ?? 'N/A'}'),
//               const SizedBox(height: 8),
//               Text('Camera Name: ${widget.alert['cameraName'] ?? 'N/A'}'),
//               const SizedBox(height: 8),
//               Text('Location: ${widget.alert['location'] ?? 'N/A'}'),
//               const SizedBox(height: 8),
//               Text('Status: ${widget.alert['status'] ?? 'N/A'}'),
//               const SizedBox(height: 8),
//               Text('Timestamp: ${getFormattedTimestamp()}'),
//               const SizedBox(height: 8),
//               Text('Type: ${widget.alert['type'] ?? 'N/A'}'),
//               const SizedBox(height: 16),

//               if (widget.alert['imageUrl'] != null &&
//                   widget.alert['imageUrl'].isNotEmpty)
//                 Image.network(widget.alert['imageUrl'])
//               else
//                 const Text('No image available'),

//               const SizedBox(height: 16),

//               if (widget.alert['cameraId'] != null)
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Livestream:',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       height: 200,
//                       child: VlcPlayer(
//                         controller: _vlcController,
//                         aspectRatio: 16 / 9,
//                         placeholder: const Center(
//                           child: Text('Loading stream...'),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.play_arrow),
//                           onPressed: () => _vlcController.play(),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.pause),
//                           onPressed: () => _vlcController.pause(),
//                         ),
//                       ],
//                     ),
//                   ],
//                 )
//               else
//                 const Text('No livestream available'),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
