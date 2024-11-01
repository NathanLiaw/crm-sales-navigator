import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class PDFViewerPage extends StatefulWidget {
  final String salesOrderId;
  final Uint8List pdfData;

  const PDFViewerPage({
    Key? key,
    required this.pdfData,
    required this.salesOrderId,
  }) : super(key: key);

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
      // Request storage access
      var status = await Permission.storage.request();
      if (status.isGranted) {
        // Get download directory
        Directory? downloadDir;
        if (Platform.isAndroid) {
          downloadDir = Directory('/storage/emulated/0/Download');
        } else if (Platform.isIOS) {
          downloadDir = await getApplicationDocumentsDirectory();
        }

        if (downloadDir != null) {
          final fileName = 'invoice_${widget.salesOrderId}.pdf';
          final filePath = path.join(downloadDir.path, fileName);
          final file = File(filePath);
          await file.writeAsBytes(widget.pdfData);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission denied'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => isLoading = false);
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
                  print(error.toString());
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
    Key? key,
    required this.totalPages,
    required this.currentPage,
  }) : super(key: key);

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
