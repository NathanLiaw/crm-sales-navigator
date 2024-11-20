// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;

class PDFViewerPage extends StatefulWidget {
  final String salesOrderId;
  final Uint8List pdfData;

  const PDFViewerPage({
    super.key,
    required this.pdfData,
    required this.salesOrderId,
  });

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  late String tempFilePath;
  bool isLoading = false;
  int? totalPages;
  int? currentPage;

  @override
  void initState() {
    super.initState();
    _saveTempFile();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = deviceInfo.version.sdkInt;

    if (sdkInt >= 33) {
      // Android 13 and above
      await Permission.photos.request();
      await Permission.videos.request();
      await Permission.audio.request();
    } else if (sdkInt >= 29) {
    } else {
      // Below Android 10
      await Permission.storage.request();
    }
  }

  Future<bool> _handlePermissions() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = deviceInfo.version.sdkInt;

    if (sdkInt >= 34) {
      // Android 14
      final images = await Permission.photos.status;
      final videos = await Permission.videos.status;

      if (!images.isGranted || !videos.isGranted) {
        final statuses = await [
          Permission.photos,
          Permission.videos,
        ].request();

        return statuses.values.every((status) => status.isGranted);
      }
      return true;
    } else if (sdkInt >= 33) {
      // Android 13
      final images = await Permission.photos.status;
      final videos = await Permission.videos.status;
      final audio = await Permission.audio.status;

      if (!images.isGranted || !videos.isGranted || !audio.isGranted) {
        final statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();

        return statuses.values.every((status) => status.isGranted);
      }
      return true;
    } else if (sdkInt >= 29) {
      // Android 10-12
      return true; // Scoped storage, no need for runtime permission
    } else {
      // Android 9 and below
      final storage = await Permission.storage.status;
      if (!storage.isGranted) {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
      return true;
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'This app needs storage permission to save invoices. Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveTempFile() async {
    final directory = await getTemporaryDirectory();
    tempFilePath = '${directory.path}/temp_${widget.salesOrderId}.pdf';
    final file = File(tempFilePath);
    await file.writeAsBytes(widget.pdfData);
    setState(() {});
  }

  Future<void> _downloadPDF() async {
    setState(() => isLoading = true);
    try {
      final hasPermission = await _handlePermissions();
      if (!hasPermission) {
        setState(() => isLoading = false);
        return;
      }

      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = deviceInfo.version.sdkInt;

        Directory? downloadDir;
        String? filePath;

        // Handle different Android versions
        if (sdkInt >= 33) {
          // Android 13 and above
          downloadDir = Directory('/storage/emulated/0/Download');
        } else if (sdkInt >= 29) {
          // Android 10 and 11
          downloadDir = Directory('/storage/emulated/0/Download');
        } else {
          // Below Android 10
          downloadDir = Directory('/storage/emulated/0/Download');
        }

        // Create download directory if it doesn't exist
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }

        // Generate filename with timestamp to avoid duplicates
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = 'invoice_${widget.salesOrderId}_$timestamp.pdf';
        filePath = path.join(downloadDir.path, fileName);

        // Save the file
        final file = File(filePath);
        await file.writeAsBytes(widget.pdfData);

        if (!mounted) return;

        // Show success message with file path
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PDF saved successfully!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: ${file.path}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PDFViewerPage(
                      pdfData: file.readAsBytesSync(),
                      salesOrderId: widget.salesOrderId,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else if (Platform.isIOS) {
        // Handle iOS
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = 'invoice_${widget.salesOrderId}_$timestamp.pdf';
        final filePath = path.join(directory.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(widget.pdfData);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF saved to Documents'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Show detailed error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error saving PDF',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                e.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: _downloadPDF,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _sharePDF() async {
    try {
      final file = XFile(tempFilePath);
      await Share.shareXFiles(
        [file],
        text: 'Invoice ${widget.salesOrderId}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openFileManager() async {
    try {
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir != null && downloadDir.existsSync()) {
        // Get the file and add the last modification time
        final files = downloadDir
            .listSync()
            .where((file) =>
                file is File &&
                path.basename(file.path).startsWith('invoice_') &&
                path.basename(file.path).endsWith('.pdf'))
            .map((file) {
          final fileStats = (file as File).statSync();
          return {
            'file': file,
            'modifiedTime': fileStats.modified,
          };
        }).toList();

        // Sort by modification time (newest first)
        files.sort((a, b) => (b['modifiedTime'] as DateTime)
            .compareTo(a['modifiedTime'] as DateTime));

        if (!mounted) return;

        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Downloaded Invoices',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${files.length} files',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (files.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No downloaded invoices yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final fileInfo = files[index];
                        final file = fileInfo['file'] as File;
                        final modifiedTime =
                            fileInfo['modifiedTime'] as DateTime;
                        final fileName = path.basename(file.path);

                        final now = DateTime.now();
                        final difference = now.difference(modifiedTime);
                        String timeDisplay;

                        if (difference.inDays == 0) {
                          timeDisplay =
                              'Today ${DateFormat('HH:mm').format(modifiedTime)}';
                        } else if (difference.inDays == 1) {
                          timeDisplay =
                              'Yesterday ${DateFormat('HH:mm').format(modifiedTime)}';
                        } else if (difference.inDays < 7) {
                          timeDisplay =
                              DateFormat('EEEE HH:mm').format(modifiedTime);
                        } else {
                          timeDisplay = DateFormat('yyyy-MM-dd HH:mm')
                              .format(modifiedTime);
                        }

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf,
                                color: Colors.red),
                            title: Text(
                              fileName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Size: ${(file.lengthSync() / 1024).toStringAsFixed(2)} KB',
                                ),
                                Text(
                                  'Downloaded: $timeDisplay',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share,
                                      color: Colors.blue),
                                  onPressed: () async {
                                    final xFile = XFile(file.path);
                                    await Share.shareXFiles([xFile]);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Invoice'),
                                        content: const Text(
                                            'Are you sure you want to delete this invoice?'),
                                        actions: [
                                          TextButton(
                                            child: const Text('Cancel'),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                          TextButton(
                                            child: const Text(
                                              'Delete',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                            onPressed: () async {
                                              await file.delete();
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                              _openFileManager();
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PDFViewerPage(
                                    pdfData: file.readAsBytesSync(),
                                    salesOrderId: fileName.replaceAll(
                                        RegExp(r'invoice_|\.pdf'), ''),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file manager: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${widget.salesOrderId}'),
        backgroundColor: const Color(0xff0175FF),
        foregroundColor: Colors.white,
        actions: [
          if (totalPages != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Page ${(currentPage ?? 0) + 1} of $totalPages',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: _openFileManager,
            tooltip: 'File Manager',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePDF,
            tooltip: 'Share PDF',
          ),
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: isLoading ? null : _downloadPDF,
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF Viewer
          FutureBuilder(
            future: Future.delayed(Duration.zero),
            builder: (context, snapshot) {
              if (tempFilePath.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return PDFView(
                filePath: tempFilePath,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: false,
                pageFling: false,
                pageSnap: false,
                fitPolicy: FitPolicy.WIDTH,
                defaultPage: currentPage ?? 0,
                fitEachPage: true,
                onRender: (pages) {
                  setState(() {
                    totalPages = pages;
                  });
                },
                onPageChanged: (int? page, int? total) {
                  setState(() {
                    currentPage = page;
                    totalPages = total;
                  });
                },
                onError: (error) {
                  developer.log(error.toString());
                },
              );
            },
          ),
          // Page Dividers
          if (totalPages != null)
            PageDividers(
              totalPages: totalPages!,
              currentPage: currentPage ?? 0,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    File(tempFilePath).delete().ignore();
    super.dispose();
  }
}

class PageDividers extends StatelessWidget {
  final int totalPages;
  final int currentPage;

  const PageDividers({
    super.key,
    required this.totalPages,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListView.builder(
        itemCount: totalPages - 1,
        itemBuilder: (context, index) {
          final pageHeight = MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight;
          final dividerPosition = (index + 1) * pageHeight;

          return Positioned(
            top: dividerPosition,
            left: 0,
            right: 0,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[400]!,
                    width: 0.5,
                  ),
                  bottom: BorderSide(
                    color: Colors.grey[400]!,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
