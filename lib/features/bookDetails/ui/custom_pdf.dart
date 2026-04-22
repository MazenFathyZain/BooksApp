import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class CustomPdf extends StatefulWidget {
  const CustomPdf({super.key});

  @override
  State<CustomPdf> createState() => _CustomPdfState();
}

class _CustomPdfState extends State<CustomPdf> {
  late final PdfViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
  }

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String pdfUrl = args['pdfUrl'];
    final String title = args['title'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _controller.zoomLevel += 0.25;
            },
          ),
        ],
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        controller: _controller,
        canShowPaginationDialog: false,
        enableDoubleTapZooming: true,
      ),
    );
  }

  @override
  void dispose() {
    // ❌ لا تستعمل closeDocument
    super.dispose();
  }
}
